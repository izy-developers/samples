import calender from './calender.js';
import {
  getShiftId,
  getMemberId,
  getMemberAvailability,
  getEmployeeInfo,
} from '../lib/employee.js';
import { convert12To24, convert24To12, convert24ToNumber, convertNumberTo24 } from '../lib/time.js';
import { hasConflict } from '../lib/validate.js';
import { debounce } from '../lib/utility.js';

import { updateShift } from '../requests.js';

const slotColors = {
  red: '#ffe9e9',
  green: '#e3ffef',
  yellow: '#fff6d7',
};

class Slot {
  constructor() {
    document.addEventListener('mousedown', this.handleDisableDragging);
    document.addEventListener('touchstart', this.handleDisableDragging);

    document.addEventListener('mouseup', this.handleEnableDragging);
    document.addEventListener('touchend', this.handleEnableDragging);
  }

  // -------------------------------
  // COLORING SLOT PART
  // -------------------------------
  markSlotAsDropZone = (slot, mode) => {
    slot.setAttribute('drop-zone', mode);
  };

  markSlotAsPartTime = (slot, startTime, endTime) => {
    slot.style.backgroundColor = slotColors.yellow;

    slot.classList.add('h-100');

    slot.innerHTML = `
          <img src='images/alert.png' />
          <span class='mt-1'> Free ${convert24To12(startTime)} - ${convert24To12(endTime)}</span>  
        `;
  };

  markSlotAsFullTime = (slot, showingAvailabilty = false) => {
    slot.style.backgroundColor = slotColors.green;

    const markup = showingAvailabilty
      ? `<img src='images/Thumbs-Up.png' />`
      : `<img src='images/Thumbs-Up.png' />
        <div class='mt-1 d-flex align-items-center gap-1 text-dark'>
          <i class="fa-solid fa-plus fs-5"></i>
          <span>Add Shift</span>
        </div>
      `;

    slot.innerHTML = markup;
  };

  markSlotAsNoTime = (slot, showingAvailabilty = false) => {
    slot.style.backgroundColor = slotColors.red;

    const markup = showingAvailabilty
      ? `<img src="images/no.png" />`
      : `
      <img src="images/no2.png" />
      <div class='mt-1 d-flex align-items-center gap-1 text-dark'>
        <i class="fa-solid fa-plus fs-5"></i>
        <span>Add Shift</span>
      </div>
    `;

    slot.innerHTML = markup;
  };

  resetSlot = (slot) => {
    slot.innerHTML = '';
    this.resetSlotBgColor(slot);
  };

  resetSlotBgColor(slot) {
    slot.style.removeProperty('background-color');
  }

  colorSlot = (memberAvailabilityPerDay, slot, mode, showingAvailabilty = false) => {
    this.markSlotAsDropZone(slot, mode);

    const isFullTime = memberAvailabilityPerDay.all_day;
    const startTime = memberAvailabilityPerDay.start;
    const endTime = memberAvailabilityPerDay.end;

    if (!startTime || !endTime) {
      this.markSlotAsNoTime(slot, showingAvailabilty);
    } else if (isFullTime) {
      this.markSlotAsFullTime(slot, showingAvailabilty);
    } else {
      this.markSlotAsPartTime(slot, startTime, endTime);
    }
  };

  addTooltip(slot, partialConflict = false, availability) {
    const shiftTooltip = slot.closest('td').querySelector('.shift_tooltip');
    if (shiftTooltip) return;

    const shiftDate = new Date(slot.dataset.date);
    const formattedDate = new Intl.DateTimeFormat('en-US', {
      weekday: 'long',
      month: 'short',
      day: 'numeric',
    }).format(shiftDate);

    const employeeId = getMemberId(slot);
    const { employeeName } = getEmployeeInfo(employeeId);
    const firstName = employeeName.split(' ')[0];

    let message = `${firstName} is set to <span style="font-weight:bold">unavailable</span>`;
    if (partialConflict) {
      const availabilityStartIn12 = convert24To12(availability.start);
      const availabilityEndIn12 = convert24To12(availability.end);

      message = `${firstName} is only available from <span style="font-weight:500">${availabilityStartIn12} to ${availabilityEndIn12}</span>`;
    }

    const markup = `
      <span class="shift_note_icon ${partialConflict ? 'yellow' : ''}"></span>
      <span class="shift_tooltip">
        <span class="date">${formattedDate}</span>
        <span class="message">${message}</span>
      </span>
      `;

    slot.closest('td').insertAdjacentHTML('afterBegin', markup);
  }

  removeTooltip(slot) {
    slot.closest('td').querySelector('.shift_note_icon')?.remove();
    slot.closest('td').querySelector('.shift_tooltip')?.remove();
  }

  updateTooltip(memberAvailability, slot, shiftTime) {
    if (!memberAvailability.start || !memberAvailability.end) {
      this.addTooltip(slot);
    } else if (hasConflict(memberAvailability, shiftTime)) {
      this.addTooltip(slot, true, memberAvailability);
    } else {
      this.removeTooltip(slot);
    }
  }

  updateSlotShiftHours = (slot, shiftHours, availability, fromSlider = false) => {
    if (fromSlider) {
      slot.dataset.shiftTime = shiftHours;
    } else {
      slot.dataset.shiftTime = shiftHours;
      slot.innerHTML = shiftHours;
    }

    this.updateTooltip(availability, slot, shiftHours);
  };

  giveSlotStyles(slot, slotType) {
    if (slotType === 'EMPTY') {
      slot.classList.add('empty-slot');
      slot.classList.remove('non-empty-slot');
    } else {
      slot.classList.remove('empty-slot');
      slot.classList.add('non-empty-slot');
    }
  }

  deleteShiftFromSlot(slot) {
    calender.emptySlots.push(slot);

    this.removeSliderStyles(slot);
    this.giveSlotStyles(slot, 'EMPTY');

    slot.removeAttribute('draggable');
    slot.removeAttribute('data-shift-id');

    this.removeTooltip(slot);
    slot.innerHTML = '';
  }

  addShiftToSlot(slot, shiftId, shiftHours) {
    calender.emptySlots = calender.emptySlots.filter((s) => s !== slot);

    this.giveSlotStyles(slot, 'NON_EMPTY');
    slot.classList.add('h-100');
    slot.setAttribute('draggable', true);
    this.resetSlotBgColor(slot);

    slot.dataset.shiftId = shiftId;

    const employeeId = getMemberId(slot);
    const selectedDay = slot.dataset.day;
    const availability = getMemberAvailability(employeeId)[selectedDay];

    this.updateSlotShiftHours(slot, shiftHours, availability);
  }

  // -------------------------------
  // SLIDER PART
  // -------------------------------
  showSlider(slot) {
    // SHOWING SLIDER
    const markup = this.#generateSliderMarkup(slot);
    slot.innerHTML = markup;
    this.#styleSlider(slot);
    this.#setSliderView(slot);

    // EVENT HANDLERS
    this.#handleMovingSlider(slot);
  }

  hideSlider(slot) {
    this.removeSliderStyles(slot);

    const { shiftTime } = slot.dataset;

    slot.innerHTML = shiftTime;
  }

  #styleSlider(slot) {
    slot.classList.add('justify-content-center');
    slot.classList.add('align-items-end');
    slot.classList.remove('align-items-center');
  }

  removeSliderStyles(slot) {
    slot.classList.remove('justify-content-center');
    slot.classList.remove('align-items-end');
    slot.classList.add('align-items-center');
  }

  handleDisableDragging(e) {
    const input = e.target;

    if (!input.classList.contains('slider-input')) return;

    input.closest('.non-empty-slot').draggable = false;
  }

  handleEnableDragging(e) {
    const input = e.target;

    if (!input.classList.contains('slider-input')) return;

    input.closest('.non-empty-slot').draggable = true;
  }

  #handleMovingSlider(slot) {
    const rangeInputs = slot.querySelectorAll('input');
    const debouncedUpdateShift = debounce(updateShift, 300);

    const gap = 1;

    rangeInputs.forEach((input) => {
      input.addEventListener('input', (e) => {
        let minVal = parseInt(rangeInputs[0].value);
        let maxVal = parseInt(rangeInputs[1].value);

        if (maxVal - minVal < gap) {
          if (e.target.classList.contains('range-min')) {
            rangeInputs[0].value = maxVal - gap;
            minVal = parseInt(rangeInputs[0].value);
          } else {
            rangeInputs[1].value = minVal + gap;
            maxVal = parseInt(rangeInputs[1].value);
          }
        }

        this.#setSliderView(slot);
        this.#updateShiftTime(slot, debouncedUpdateShift);
      });
    });
  }

  #updateShiftTime(slot, debouncedUpdateShift) {
    const rangeInputs = slot.querySelectorAll(`input`);
    const memberId = getMemberId(slot);
    const shiftId = getShiftId(slot);
    const shiftDay = slot.dataset.day;

    const startTimeIn24 = convertNumberTo24(rangeInputs[0].value);
    const endTimeIn24 = convertNumberTo24(rangeInputs[1].value);
    const shiftHours = `${convert24To12(startTimeIn24)} - ${convert24To12(endTimeIn24)}`;

    const availability = getMemberAvailability(memberId)[shiftDay];
    debouncedUpdateShift(shiftId, memberId, startTimeIn24, endTimeIn24);

    this.updateSlotShiftHours(slot, shiftHours, availability, true);
  }

  #setSliderView(slot) {
    const rangeInputs = slot.querySelectorAll(`input`);
    const progressBar = slot.querySelector('.progress');
    const timeLabel = slot.querySelector(`.time-label`);

    const minVal = rangeInputs[0].value;
    const maxVal = rangeInputs[1].value;

    progressBar.style.left =
      ((minVal - rangeInputs[0].min) / (rangeInputs[0].max - rangeInputs[0].min)) * 100 + '%';
    progressBar.style.right =
      100 - ((maxVal - rangeInputs[1].min) / (rangeInputs[1].max - rangeInputs[1].min)) * 100 + '%';

    const startTimeIn24 = convertNumberTo24(minVal);
    const endTimeIn24 = convertNumberTo24(maxVal, true);

    timeLabel.innerHTML = `${convert24To12(startTimeIn24)} - ${convert24To12(endTimeIn24)} (${
      (maxVal - minVal) / 4
    } hrs)`;
  }

  #generateSliderMarkup(slot) {
    const [startTimeIn12, endTimeIn12] = slot.dataset.shiftTime.split('-');
    let [startTimeIn24, endTimeIn24] = [startTimeIn12, endTimeIn12].map((time) =>
      convert12To24(time)
    );

    const startValue = convert24ToNumber(startTimeIn24);
    const endValue = convert24ToNumber(endTimeIn24, true);

    return `
            <button class='position-absolute btn p-0 delete-shift-button border-0 delete-shift-btn' role="button" style='pointer-events:auto;'><i class="fa-regular  fa-circle-xmark"></i></button>  
            <div id='slider' class="slider-wrapper w-100 position-relative">
              <span class="time-label d-flex flex-column">10:00 - 00:00 (11 hrs)</span>
              <div class="slider">
                <div class="progress"></div>
              </div>
              <div class="range-input">
                <input type="range" class="slider-input range-min start-0" name="" id="" min="0" max="96" value="${startValue}" />
                <input type="range" class="slider-input range-max start-0" name="" id="" min="0" max="96" value="${endValue}" />
              </div>
            </div>
            `;
  }
}

export default new Slot();
