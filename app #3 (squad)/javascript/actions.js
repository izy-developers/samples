import { getCurrentDate } from '../lib/time.js';
import { deleteSchedule } from '../requests.js';
import calender from './calender.js';
import { addEmployeeCard } from './employeesCards.js';
import { TOKEN } from '../config.js';
import { archivedEmployees } from '../lib/employee.js';

// DOM ELEMENTS
const actionsList = document.querySelectorAll('.action');
const actionsTitle = document.querySelector('.action-title');
let checkedInputs = [...document.querySelectorAll('.member input')].filter((inp) => inp.checked);

function confirm_clear_schdule() {
  if (!confirm('Are you sure you want to clear the current schedule?')) return;

  fetch('/schedule/clear', {
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': TOKEN },
    method: 'POST',
    body: JSON.stringify({ date: getCurrentDate() }),
  })
    .then((res) => res.json())
    .then((data) => {
      console.log(data);
      location.reload();
    });
}

const handleDuplicate = () => {
  $.post('/shifts/duplicate', { date: getCurrentDate() }, function (response) {
    if (response.success) {
      window.location.reload();
    } else {
      alert(response.errors);
    }
  });
};

const handleRemoveSchedule = () => {
  const selectedEmployeesIds = checkedInputs.map((el) => el.closest('.member').dataset.memberId);

  $('#remove_employees_action').hide();
  deleteSchedule(selectedEmployeesIds);
  selectedEmployeesIds.forEach((id) => {
    if(archivedEmployees(id)){
      addEmployeeCard(id);
    }
    calender.removeEmployeeRows(id);
    actionsTitle.innerHTML = 'Shortcuts';
  });
};

const handle_action = (action) => {
  if (action === 'duplicate') {
    handleDuplicate();
  } else if (action === 'remove') {
    handleRemoveSchedule();
    window.location.reload();
  } else if (action === 'clear_schdule') {
    confirm_clear_schdule();
  }
};

actionsList.forEach((el) => {
  el.addEventListener('click', () => {
    const action = el.dataset.action;
    handle_action(action);
  });
});

calender.calenderEl.addEventListener('change', (e) => {
  if (!e.target.matches('input[type="checkbox"]')) return;
  checkedInputs = [...document.querySelectorAll('.member input')].filter((inp) => inp.checked);

  if (checkedInputs.length) {
    actionsTitle.innerHTML = `<span class="employees_selected_icon">${checkedInputs.length}</span>
    <span>Staff Members Selected</span>`;
  } else {
    actionsTitle.innerHTML = 'Shortcuts';
  }
});
