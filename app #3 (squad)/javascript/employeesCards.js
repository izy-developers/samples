import { getEmployeeImage, getEmployeeInfo, getMemberId } from '../lib/employee.js';

// ----------------------------------
//  DOM ELEMENTS
// ----------------------------------
const leftArrow = document.getElementById('left-arrow');
const rightArrow = document.getElementById('right-arrow');
const employeesCardsContainer = document.querySelector('.members');
const userImage = document.querySelector('.profile-logo img');

// ----------------------------------
// FUNCTIONS
// ----------------------------------
const checkArrowsVisibilty = () => {
  if (employeesCardsContainer.scrollLeft === 0) {
    leftArrow.classList.add('hidden');
  } else {
    leftArrow.classList.remove('hidden');
  }

  if (
    employeesCardsContainer.scrollWidth -
      (employeesCardsContainer.scrollLeft + employeesCardsContainer.offsetWidth) <
    5
  ) {
    rightArrow.classList.add('hidden');
  } else {
    rightArrow.classList.remove('hidden');
  }
};

const positionArrows = () => {
  const { top, height } = employeesCardsContainer.getBoundingClientRect();

  leftArrow.style.top = `${document.documentElement.scrollTop + top + height / 2}px`;
  rightArrow.style.top = `${document.documentElement.scrollTop + top + height / 2}px`;

  leftArrow.style.left = `${50 + document.documentElement.scrollLeft}px`;
  rightArrow.style.right = `${50 - document.documentElement.scrollLeft}px`;

  if (
    employeesCardsContainer.scrollWidth ===
    employeesCardsContainer.scrollLeft + employeesCardsContainer.offsetWidth
  ) {
    rightArrow.classList.add('hidden');
  }
};

const cardsContainerScroll = (direction, scrollBy) => {
  const sign = direction === 'LEFT' ? '-' : '+';

  employeesCardsContainer.scrollBy({
    left: `${sign}${scrollBy}`,
    behavior: 'smooth',
  });
};

const generateCardMarkup = ({
  employeeId,
  employeeName,
  employeeRole,
  avatarUrl,
  roleBgColor,
  roleTextColor,
}) => {
  const employeeImage = getEmployeeImage(avatarUrl, employeeName);

  return `
        <div class="d-flex member dashed align-items-center employee-card bg-white flex-shrink-0" draggable="true" data-member-id=${employeeId}>
          ${employeeImage}
          <div class="member__info d-flex flex-column align-items-baseline">
            <span class="member__name d-inline-block overflow-hidden text-capitalize text-container">${employeeName}</span>
            <span style="color: ${roleTextColor}; background-color: ${roleBgColor}" class="member__role rounded-1 overflow-hidden text-capitalize small-font">${employeeRole}</span>
          </div>
          <div class="edit-icon"><img src="/images/edit-pencil.png" alt="edit icon"></div>
        </div>
    `;
};

export const removeEmployeeCard = (employeeId) => {
  unAssignedEmployees = unAssignedEmployees.filter((employee) => +employee.id !== +employeeId);
  const selectedEmployeeCard = document.querySelector(`[data-member-id="${employeeId}"]`);
  selectedEmployeeCard.remove();

  checkArrowsVisibilty();
};

export const addEmployeeCard = (employeeId) => {
  const { employeeName, employeeRole, avatarUrl, roleBgColor, roleTextColor } =
    getEmployeeInfo(employeeId);

  const markup = generateCardMarkup({
    employeeId,
    employeeName,
    employeeRole,
    avatarUrl,
    roleBgColor,
    roleTextColor,
  });
  employeesCardsContainer.insertAdjacentHTML('beforeend', markup);

  unAssignedEmployees.push({ id: employeeId, name: employeeName });
  checkArrowsVisibilty();
};

// ----------------------------------
//  ARROW LOGIC
// ----------------------------------

positionArrows();
userImage?.addEventListener('load', positionArrows);

leftArrow.addEventListener('click', () => {
  cardsContainerScroll('LEFT', 300);
});

rightArrow.addEventListener('click', () => {
  cardsContainerScroll('RIGHT', 300);
});

window.addEventListener('scroll', () => {
  leftArrow.style.left = `${50 + document.documentElement.scrollLeft}px`;
  rightArrow.style.right = `${50 - document.documentElement.scrollLeft}px`;
});

employeesCardsContainer.addEventListener('scroll', () => {
  checkArrowsVisibilty();
});

// ----------------------------------
//  MEMBERS LOGIC
// ----------------------------------

employeesCardsContainer.addEventListener('click', (e) => {
  const editIcon = e.target.closest('.edit-icon');

  if (!editIcon) return;

  const employeeId = getMemberId(e.target.closest('.employee-card'));

  show_edit_modal(employeeId);
});
