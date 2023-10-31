import {
  getShiftId,
  getMemberId,
  getEmployeeInfo,
  getEmployeeImage,
  getMemberAvailability,
} from '../lib/employee.js';
import { getWeekDays, convert12To24 } from '../lib/time.js';
import { mobileCheck, getCookie, setCookie } from '../lib/navigator.js';

import { DEFAULT_SHIFT_HOURS } from '../config.js';

import { createShift, transferShift, deleteShift, getWeekTotal } from '../requests.js';

import Slot from './Slot.js';
import overlay from './overlay.js';
import { addEmployeeCard, removeEmployeeCard } from './employeesCards.js';

let draggedEl;

class Calender {
  // DOM ELEMENTS
  #employeesCardsContainer = document.querySelector('.members');
  calenderEl = document.getElementById('calender');
  #addShiftSlots = document.querySelectorAll('#calender .add-shift-slot');
  emptySlots = [...document.querySelectorAll('.empty-slot')];
  #nonEmptySlots = [...document.querySelectorAll('.non-empty-slot')];

  // STATE
  #addingShift;
  #transferingShift;

  constructor() {
    this.#addingShift = false;
    this.#transferingShift = false;

    this.#configureEventHandlers();

    this.addShiftsTooltips();
    this.updateCalenderTotals(true);
    this.showMobileWarning();
    this.#polyfillingDragDropForTouchDevices();
  }

  #configureEventHandlers() {
    this.#employeesCardsContainer.addEventListener(
      'dragstart',
      this.#handleEmployeesDragStart.bind(this)
    );

    this.#employeesCardsContainer.addEventListener(
      'dragend',
      this.#handleEmployeesDragEnd.bind(this)
    );

    this.calenderEl.addEventListener('dragstart', this.#handleShiftDragStart.bind(this));

    this.calenderEl.addEventListener('dragend', this.#handleShiftDragEnd.bind(this));

    this.calenderEl.addEventListener('dragenter', this.#handleSlotDragEnter.bind(this));

    this.calenderEl.addEventListener('dragleave', this.#handleSlotDragLeave.bind(this));

    this.calenderEl.addEventListener('dragover', this.#handleCalenderDragOver.bind(this));

    this.calenderEl.addEventListener('drop', this.#handleCalenderDrop.bind(this));

    this.#employeesCardsContainer.addEventListener(
      'mouseenter',
      this.#handleEmployeesCardsMouseEnter.bind(this),
      true
    );

    this.#employeesCardsContainer.addEventListener(
      'mouseleave',
      this.#handleEmployeesCardsMouseLeave.bind(this),
      true
    );

    this.calenderEl.addEventListener('mouseenter', this.#handleSlotMouseEnter.bind(this), true);

    this.calenderEl.addEventListener('mouseleave', this.#handleSlotMouseLeave.bind(this), true);

    this.calenderEl.addEventListener('click', this.#handleDeleteShift.bind(this));

    this.calenderEl.addEventListener('click', this.#handleShiftSlotClick.bind(this));

    this.calenderEl.addEventListener('click', this.#handleEmptySlotClick.bind(this));
  }

  // HELPERS
  #showMemberAvailabitly = (employeeId) => {
    const memberAvailability = getMemberAvailability(employeeId);

    this.#addShiftSlots.forEach((slot) => {
      const dayName = slot.dataset.day;
      Slot.colorSlot(memberAvailability[dayName], slot, null, true);
    });
  };
  moveRowsToTop(employeeId) {
    const firstRowInCalender = this.calenderEl.querySelector('tbody tr').nextElementSibling;
    const firstEmployeeRow = this.calenderEl.querySelector(`[data-member-id="${employeeId}"]`);

    if (firstEmployeeRow === firstRowInCalender) return;

    const memberInfoSlot = firstEmployeeRow.querySelector('td');

    const numExistingRows = +memberInfoSlot.rowSpan;

    let curRow = firstEmployeeRow;

    for (let i = 0; i < numExistingRows; i++) {
      firstRowInCalender.insertAdjacentElement('beforebegin', curRow);
      curRow = curRow.nextElementSibling;
    }
  }
  isRowEmpty(row) {
    return [...row.querySelectorAll('.non-empty-slot')].length > 0 ? false : true;
  }

  // FULL_ROW LOGIC
  #generateEmployeeRowMarkup({
    employeeId,
    employeeName,
    employeeRole,
    roleBgColor,
    roleTextColor,
    avatarUrl,
  }) {
    const employeeImage = getEmployeeImage(avatarUrl, employeeName);

    const parser = new URL(window.location);
    const selectedDay = parser.searchParams.get('date');
    const weekDaysDates = getWeekDays(selectedDay);
    const weekDaysNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return `
    <tr data-member-id="${employeeId}">
      <td class="bg-white align-middle">
        <div class="member align-items-center d-flex ps-3 w-100 h-100 justify-content-start position-relative"" data-member-id="${employeeId}">
          <div class="position-absolute p-3 bg-white border schedule_tooltip">
            <span class="text-capitalize mb-2"> this week </span>
            <span class="d-block"><span data-week-hours="">0</span> hrs • $ <span data-week-budget="">00.00</span> </span>
          </div>  
          ${employeeImage}
          <div class="member__info d-flex flex-column align-items-baseline flex-grow-1">
            <span class="member__name text-truncate">${employeeName}</span>
            <span style="color:${roleTextColor}; background-color: ${roleBgColor}" class="member__role text-capitalize rounded-1 small-font">${employeeRole}</span>
          </div>
          <div class="custom_checkbox member-label">
            <label>
                <input type="checkbox" class="employee_checkbox">
                <span class="checkmark border rounded-3"></span>
            </label>
        </div>
        </div>
      </td>
      ${weekDaysNames
        .map(
          (day, i) => `
            <td class="position-relative">
              <div data-date="${weekDaysDates[i].year}-${(weekDaysDates[i].month + 1)
            .toString()
            .padStart(2, 0)}-${weekDaysDates[i].dayOfTheMonth
            .toString()
            .padStart(
              2,
              0
            )}" data-member-id="${employeeId}" data-day="${day}" class="empty-slot flex-column position-relative"></div>
            </td>
        `
        )
        .join(' ')}
    </ tr>          
    `;
  }
  #configureNewRow(insertedRow) {
    const newEmptySlots = [...insertedRow.querySelectorAll('.empty-slot')];

    newEmptySlots.forEach((slot) => {
      this.emptySlots.push(slot);
    });
  }
  insertEmployeeRow(employeeData, newEmployee = false) {
    const { employeeId } = employeeData;

    const markup = this.#generateEmployeeRowMarkup(employeeData);

    newEmployee || removeEmployeeCard(employeeId);

    const calenderFirstRow = document.querySelector('#calender tbody tr');

    calenderFirstRow.insertAdjacentHTML('afterend', markup);
    const insertedRow = calenderFirstRow.nextElementSibling;
    this.#configureNewRow(insertedRow);
  }
  removeEmployeeRows(employeeId) {
    const firstEmployeeRow = this.calenderEl.querySelector(`[data-member-id="${employeeId}"]`);

    const memberInfoSlot = firstEmployeeRow.querySelector('td');

    const numExistingRows = +memberInfoSlot.rowSpan;

    let currentRow = firstEmployeeRow;

    for (let i = 0; i < numExistingRows; i++) {
      const nextRow = currentRow.nextElementSibling;
      currentRow.remove();
      currentRow = nextRow;
    }
  }

  // SLOTS_ROW LOGIC
  generateSlotsRowMarkup(employeeId) {
    const parser = new URL(window.location);
    const selectedDay = parser.searchParams.get('date');
    const weekDaysDates = getWeekDays(selectedDay);

    const weekDaysNames = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday',
    ];

    return `
      ${weekDaysNames
        .map(
          (day, i) => `
            <td class="position-relative">
              <div data-date="${weekDaysDates[i].year}-${(weekDaysDates[i].month + 1)
            .toString()
            .padStart(2, 0)}-${weekDaysDates[i].dayOfTheMonth
            .toString()
            .padStart(
              2,
              0
            )}" data-member-id="${employeeId}" data-day="${day}" class="empty-slot flex-column position-relative"></div>
            </td>
        `
        )
        .join(' ')}
    `;
  }
  configureNewSlotsRow(employeeId) {
    const newEmptySlots = [...document.querySelectorAll(`[data-member-id="${employeeId}"]`)].slice(
      -7
    );

    newEmptySlots.forEach((slot) => this.emptySlots.push(slot));
  }
  insertSlotsRow(employeeId) {
    const existingEmployeeRow = this.calenderEl
      .querySelector(`[data-member-id="${employeeId}"]`)
      .closest('tr');
    const memberInfoSlot = existingEmployeeRow.querySelector('td');

    const numExistingRows = +memberInfoSlot.rowSpan;

    memberInfoSlot.rowSpan = numExistingRows + 1;

    let lastRow = existingEmployeeRow;

    for (let i = numExistingRows - 1; i > 0; i--) {
      lastRow = lastRow.nextElementSibling;
    }

    const markup = this.generateSlotsRowMarkup(employeeId);
    lastRow.insertAdjacentHTML('afterend', markup);
    this.configureNewSlotsRow(employeeId);
  }
  removeSlotsRow(firstEmployeeRow) {
    [...firstEmployeeRow.querySelectorAll('td')].slice(1).forEach((el) => {
      el.remove();
    });

    const nextRow = firstEmployeeRow.nextElementSibling;
    const nextRowContent = nextRow.innerHTML;
    nextRow.remove();

    firstEmployeeRow.insertAdjacentHTML('beforeend', nextRowContent);
  }

  addShift(employeeId, shiftId, selectedDate, shiftHours = DEFAULT_SHIFT_HOURS.range) {
    const firstEmptySlot = document.querySelector(
      `[data-member-id="${employeeId}"][data-date="${selectedDate}"].empty-slot`
    );

    const isRowExist = !!this.calenderEl.querySelector(`[data-member-id="${employeeId}"]`);
    const isEnoughSpace = !!firstEmptySlot;

    if (isRowExist && isEnoughSpace) {
      Slot.addShiftToSlot(firstEmptySlot, shiftId, shiftHours);
    } else if (isRowExist && !isEnoughSpace) {
      this.insertSlotsRow(employeeId);
      this.addShift(employeeId, shiftId, selectedDate, shiftHours);
    } else if (!isRowExist) {
      const employeeInfo = getEmployeeInfo(employeeId);
      this.insertEmployeeRow(employeeInfo);
      this.addShift(employeeId, shiftId, selectedDate, shiftHours);
    }
  }

  updateShift(shiftId, newStartTime, newEndTime) {
    const updatedSlot = document.querySelector(`[data-shift-id="${shiftId}"]`);

    const shiftHours = `${newStartTime} - ${newEndTime}`;

    const employeeId = getMemberId(updatedSlot);
    const day = updatedSlot.dataset.day;
    const memberAvailability = getMemberAvailability(employeeId)[day];

    Slot.updateSlotShiftHours(updatedSlot, shiftHours, memberAvailability);
  }

  deleteShift(slot) {
    Slot.deleteShiftFromSlot(slot);

    const row = slot.closest('tr');
    const isRowEmpty = this.isRowEmpty(row);
    if (!isRowEmpty) return;

    const employeeId = getMemberId(slot);
    const firstEmployeeRow = this.calenderEl.querySelector(`[data-member-id="${employeeId}"]`);

    const isFirstRow = row === firstEmployeeRow;

    const memberInfoSlot = firstEmployeeRow.querySelector('td');
    const numOfRows = +memberInfoSlot.rowSpan;
    const isMultipleRows = numOfRows > 1 ? true : false;

    if (isFirstRow && isMultipleRows) {
      memberInfoSlot.rowSpan = numOfRows - 1;
      this.removeSlotsRow(firstEmployeeRow);
    } else if (isFirstRow) {
      row.remove();
      addEmployeeCard(employeeId);
    } else {
      memberInfoSlot.rowSpan = numOfRows - 1;
      row.remove();
    }
  }

  transferShift(shiftId, transferFrom, transferTo) {
    const shiftHours = transferFrom.dataset.shiftTime;
    const selectedDate = transferTo.dataset.date;
    const employeeId = getMemberId(transferTo);

    const isInTheSameRow = transferFrom.closest('tr') === transferTo.closest('tr');

    if (isInTheSameRow) {
      Slot.deleteShiftFromSlot(transferFrom);
    } else {
      this.deleteShift(transferFrom);
    }

    this.addShift(employeeId, shiftId, selectedDate, shiftHours);

    transferTo.removeAttribute('drop-zone');
    this.#handleShiftDragEnd({ target: transferFrom });
  }

  // HANDLERS
  #handleEmployeesDragStart(e) {
    const target = e.target;
    if (!target.classList.contains('employee-card')) return;
    target.dataset.position = JSON.stringify({ x: e.x, y: e.y });

    this.#addingShift = true;

    target.classList.add('dragged');
    draggedEl = target;

    overlay.show();

    const employeeId = getMemberId(e.target);

    const memberAvailability = getMemberAvailability(employeeId);

    this.#addShiftSlots.forEach((slot) => {
      const memberAvailabilityPerDay = memberAvailability[slot.dataset.day];
      Slot.colorSlot(memberAvailabilityPerDay, slot, 'create');
    });
  }

  #handleEmployeesDragEnd(e) {
    const target = e.target;
    if (!target.classList.contains('employee-card')) return;

    this.#addingShift = false;
    e.target.classList.remove('dragged');

    overlay.hide();

    this.#addShiftSlots.forEach((slot) => {
      Slot.resetSlot(slot);
    });
  }

  #handleShiftDragStart(e) {
    if (!e.target.classList?.contains('non-empty-slot')) return;

    this.#transferingShift = true;

    e.target.classList.add('titled');
    draggedEl = e.target;

    e.target.dataset.position = JSON.stringify({ x: e.x, y: e.y });

    this.emptySlots.forEach((slot) => {
      const employeeId = getMemberId(slot);

      const memberAvailability = getMemberAvailability(employeeId);

      const memberAvailabilityPerDay = memberAvailability && memberAvailability[slot.dataset.day];

      Slot.colorSlot(memberAvailabilityPerDay, slot, 'update');
    });
  }

  #handleShiftDragEnd(e) {
    if (!e.target.classList?.contains('non-empty-slot')) return;

    this.#transferingShift = false;
    e.target.classList.remove('titled');

    this.emptySlots.forEach((slot) => {
      Slot.resetSlot(slot);
    });
  }

  #handleCalenderDragOver(e) {
    let isDropZone;
    if (this.#addingShift) {
      isDropZone = e.target.getAttribute('drop-zone') === 'create';
    } else {
      isDropZone = e.target.getAttribute('drop-zone') === 'update';
    }
    if (isDropZone) e.preventDefault();
  }

  #handleSlotDragEnter(e) {
    const slot = e.target;
    if (
      (slot.classList.contains('add-shift-slot') && this.#addingShift) ||
      (slot.classList.contains('empty-slot') && this.#transferingShift)
    ) {
      slot.classList.add('highlighted_slot');
      // Slot.resetSlot(slot);
    }
  }

  #handleSlotDragLeave(e) {
    const slot = e.target;

    if (
      (slot.classList.contains('add-shift-slot') && this.#addingShift) ||
      (slot.classList.contains('empty-slot') && this.#transferingShift)
    ) {
      slot.classList.remove('highlighted_slot');

      // const employeeId = getMemberId(draggedEl);
      // const memberAvailability = getMemberAvailability(employeeId);
      // const memberAvailabilityPerDay = memberAvailability[slot.dataset.day];
      // Slot.colorSlot(memberAvailabilityPerDay, slot, 'create');
    }
  }

  // NEED REFACTORING
  #handleCalenderDrop(e) {
    const target = e.target;

    const selectedDate = target.dataset.date;
    const { x, y } = JSON.parse(draggedEl.dataset.position);

    if (this.#addingShift) {
      target.classList.remove('highlighted_slot');
      this.#addingShift = false;
      const employeeId = getMemberId(draggedEl);

      const newShift = {
        date: selectedDate,
        start_at: '09:00',
        end_at: '17:00',
      };

      createShift(employeeId, [newShift]).then((data) => {
        const [createdShift] = data.created_shifts;

        const shiftId = createdShift.id;
        const shiftDate = createdShift.start_at.slice(0, 10);

        this.addShift(employeeId, shiftId, shiftDate);

        // WORKAROUND TO FORCE CALLING (handleEmployeesDragEnd) FUNCTION
        setTimeout(() => {
          this.#handleEmployeesCardsMouseLeave({
            target: document.elementFromPoint(x, y).closest('.member'),
          });
        }, 0);
      });
    } else if (this.#transferingShift) {
      const employeeId = getMemberId(target);
      const shiftId = getShiftId(draggedEl);

      transferShift(shiftId, employeeId, selectedDate);

      setTimeout(() => {
        this.#handleSlotMouseLeave({ target: document.elementFromPoint(x, y) }, true);
      }, 0);

      this.#handleSlotDragLeave({ target: target });
      this.#handleShiftDragEnd({ target: draggedEl });

      this.transferShift(shiftId, draggedEl, target);
    }
  }

  #handleEmployeesCardsMouseEnter(e) {
    const card = e.target;
    if (!card.classList.contains('member')) return;
    card.classList.add('titled');
    const employeeId = getMemberId(card);
    this.#showMemberAvailabitly(employeeId);
  }

  #handleEmployeesCardsMouseLeave(e) {
    const card = e.target;
    if (e.target === null || !card.classList.contains('member')) return;
    card.classList.remove('titled');
    this.#addShiftSlots.forEach((slot) => {
      Slot.resetSlot(slot);
    });
  }

  #handleSlotMouseEnter(e) {
    const slot = e.target;

    if (slot.classList?.contains('empty-slot')) {
      const employeeId = getMemberId(slot);

      const memberAvailability = getMemberAvailability(employeeId);

      const memberAvailabilityPerDay = memberAvailability[slot.dataset.day];

      Slot.colorSlot(memberAvailabilityPerDay, slot, 'create');
    } else if (slot.classList?.contains('non-empty-slot')) {
      Slot.showSlider(slot);
    }
  }

  #handleSlotMouseLeave(e) {
    const slot = e.target;
    if (slot.classList?.contains('empty-slot')) {
      Slot.resetSlot(slot);
    } else if (slot.classList?.contains('non-empty-slot')) {
      Slot.hideSlider(slot);
    }
  }

  #handleEmptySlotClick(e) {
    const slot = e.target;
    if (!slot.classList.contains('empty-slot')) return;

    const employeeId = getMemberId(slot);
    const selectedDate = slot.dataset.date;

    const newShift = {
      date: selectedDate,
      start_at: convert12To24(DEFAULT_SHIFT_HOURS.startAt),
      end_at: convert12To24(DEFAULT_SHIFT_HOURS.endAt),
    };

    createShift(employeeId, [newShift]).then((data) => {
      const [createdShift] = data.created_shifts;

      const shiftId = createdShift.id;
      const shiftDate = createdShift.start_at.slice(0, 10);

      this.addShift(employeeId, shiftId, shiftDate);

      // WORKAROUND TO FORCE SHOWING THE SLIDER AFTER ADDING SHIFT
      this.#handleSlotMouseEnter({ target: slot });
    });
  }

  #handleShiftSlotClick(e) {
    const target = e.target;
    if (!target.classList.contains('non-empty-slot') || target.closest('input')) return;

    const shiftId = getShiftId(target);

    loadEditShiftModal(shiftId);
  }

  #handleDeleteShift(e) {
    const deleteButton = e.target.closest('.delete-shift-button');
    if (!deleteButton) return;

    const slot = deleteButton.closest('.non-empty-slot');
    const shiftId = getShiftId(slot);

    deleteShift(shiftId);
    this.deleteShift(slot);
  }

  addShiftsTooltips() {
    this.#nonEmptySlots.forEach((slot) => {
      const employeeId = getMemberId(slot);
      const memberAvailabity = getMemberAvailability(employeeId)[slot.dataset.day];
      const shiftHours = slot.dataset.shiftTime;

      Slot.updateTooltip(memberAvailabity, slot, shiftHours);
    });
  }

  updateEmployeeTooltip(employeeId, hours, budget) {
    const employeeRow = this.calenderEl.querySelector(`[data-member-id="${employeeId}"]`);
    const hoursSpan = employeeRow.querySelector('[data-week-hours]');
    const budgetSpan = employeeRow.querySelector('[data-week-budget]');

    hoursSpan.innerHTML = hours;
    budgetSpan.innerHTML = budget;
  }

  updateEmployeesTotals(membersBudget) {
    membersBudget.forEach((memberBudget) => {
      const { member_id, hours, budget } = memberBudget;
      this.updateEmployeeTooltip(member_id, hours, budget);
    });
  }

  async updateCalenderTotals(initializing) {
    const { members_budget: membersBudget, totals } = await getWeekTotal();

    this.updateEmployeesTotals(membersBudget);
    if (!initializing) {
      refresh_totals(totals);
    }
  }

  #polyfillingDragDropForTouchDevices = () => {
    const ua = window.navigator.userAgent.toLowerCase();
    const isiPad =
      ua.indexOf('ipad') > -1 || (ua.indexOf('macintosh') > -1 && 'ontouchend' in document);

    const usePolyfill = MobileDragDrop.polyfill({
      forceApply: isiPad, // force apply for ipad
      dragImageTranslateOverride:
        MobileDragDrop.scrollBehaviourDragImageTranslateOverride || isiPad,
    });

    if (usePolyfill) {
      document.addEventListener('dragenter', (event) => event.preventDefault());
      window.addEventListener('touchmove', () => {}, { passive: false });
    }
  };

  showMobileWarning() {
    const not_show_desktop_suggestion = getCookie('not_show_desktop_suggestion');
    if (!mobileCheck() || not_show_desktop_suggestion) return;

    setCookie('not_show_desktop_suggestion', 'true', 1); // Expires in 1 hour

    const mobileWarningEl = new bootstrap.Offcanvas(document.getElementById('mobileWarning'));
    mobileWarningEl.show();
  }
}

export default new Calender();
