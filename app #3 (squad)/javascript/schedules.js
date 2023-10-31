import { TOKEN } from '../config.js';
// ELEMENTS
const newScheduleBtn = document.getElementById('new_schedule_btn');
const newScheduleModal = document.getElementById('new_schedule_modal');
const newScheduleModalBs = new bootstrap.Modal(newScheduleModal);
const editScheduleModal = document.getElementById('editScheduleModal');
const schedules = [...document.querySelectorAll('#schedules_picker_list li')].slice(1);
const deleteScheduleBtn = document.querySelector('.delete_schedule_btn');
const renameScheduleBtn = document.querySelector('.rename_schedule_btn');
const scheduleName = document.getElementById('schedule_name');

function deleteSchedule(schedule_id) {
  fetch(`/schedule/${schedule_id}`, {
    method: 'DELETE',
    body: JSON.stringify({ schedule_id }),
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': TOKEN },
  }).then(function (response) {
    if (response.ok) {
      window.location.reload();
    } else {
      response.json().then(function (data) {
        alert(data.message);
      });
    }
  });
}

function change_current_schedule(schedule_id) {
  // Reload page setting the new schedule id
  $.post(
    `/schedule/${schedule_id}/change_current`,
    { authenticity_token: TOKEN },
    function (response) {
      if (response.success == true) {
        location.reload();
      } else {
        alert(response.message);
      }
    }
  );
}

const renameSchedule = (scheduleId, newName) => {
  fetch(`/schedule/${scheduleId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': TOKEN },
    body: JSON.stringify({ name: newName }),
  })
    .then((res) => res.json())
    .then((data) => {
      location.reload();
    });
};

const updateScheduleIdInEditModal = (id) => {
  editScheduleModal.dataset.scheduleId = id;
};
const getScheduleId = (node) => node.dataset.scheduleId;

// LOGIC
// newScheduleBtn.addEventListener('click', () => {
//   newScheduleModalBs.show();
// });

schedules.forEach((schedule) => {
  const scheduleId = getScheduleId(schedule);
  const changeScheduleBtn = schedule.querySelector('a');
  const newScheduleModalBtn = schedule.querySelector('button');

  changeScheduleBtn.addEventListener('click', (e) => {
    change_current_schedule(scheduleId);
  });
  newScheduleModalBtn.addEventListener('click', (e) => {
    console.log(scheduleId);
    updateScheduleIdInEditModal(scheduleId);
  });
});

deleteScheduleBtn.addEventListener('click', (e) => {
  const scheduleId = document.querySelector('.delete_schedule_btn').value;
  deleteSchedule(scheduleId);
});

renameScheduleBtn.addEventListener('click', () => {
  const scheduleId = document.getElementById('editScheduleModal').value;
  const newScheduleName = scheduleName.value;

  renameSchedule(scheduleId, newScheduleName);
});
if(document.getElementById('close') != null){
    document.getElementById('close').addEventListener('click', (e) => {
      document.getElementById('notif-mode').classList.remove('shadow-x')
      document.getElementById('notif-mode-one').classList.add('hide')
      document.getElementById('header-container-a').classList.remove('phone');
      document.getElementById('phone-w').classList.remove('phone-w');
      document.getElementById('phone-s').classList.remove('phone-s');
      document.getElementById('phone-c').classList.remove('phone-c');
      document.getElementById('phone-c').classList.add('normal-width');
      document.getElementById('header-container-a').classList.add('normal-width-header');
      document.getElementById('header-container-a').classList.remove('normal-color');
      document.getElementById('phone-w').classList.add('normal-width-header');
      document.getElementById('right-arrow').classList.add('phone-c');
    });
}

if(document.getElementById('btn-close') != null){
document.getElementById('btn-close').addEventListener('click', (e) => {
  document.getElementById('notif-mode').classList.remove('shadow-x')
  document.getElementById('notif-mode-one').classList.add('hide')
  document.getElementById('header-container-a').classList.remove('phone');
  document.getElementById('phone-w').classList.remove('phone-w');
  document.getElementById('phone-s').classList.remove('phone-s');
  document.getElementById('phone-c').classList.remove('phone-c');
  document.getElementById('phone-c').classList.add('normal-width');
  document.getElementById('header-container-a').classList.add('normal-width-header');
  document.getElementById('header-container-a').classList.remove('normal-color');
  document.getElementById('phone-w').classList.add('normal-width-header');
  document.getElementById('right-arrow').classList.add('phone-c');
});
}
