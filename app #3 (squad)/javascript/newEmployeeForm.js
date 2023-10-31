import { getEmployeeInfo } from '../lib/employee.js';
import { validateUploadedImage } from '../lib/validate.js';
import calender from './calender.js';
import { createEmployee } from '../requests.js';
import Autocompletiton from '../Autocompletion.js';

class newEmployeeForm {
  #addEmployeeSlot;
  #addEmployeeForm;
  #nameField;
  #roleField;
  #avatarLabel;
  #avatarField;
  #submitBtn;
  #isFormShown;
  #autocompletion;

  constructor() {
    this.#addEmployeeSlot = document.getElementById('add-employee');
    this.#addEmployeeForm = this.#addEmployeeSlot.querySelector('#add-employee-form');
    this.#nameField = this.#addEmployeeSlot.querySelector('#name-field');
    this.#roleField = this.#addEmployeeSlot.querySelector('#role-field');
    this.#avatarLabel = this.#addEmployeeSlot.querySelector('#avatar-field-label');
    this.#avatarField = this.#addEmployeeSlot.querySelector('#avatar-field');
    this.#submitBtn = this.#addEmployeeSlot.querySelector('#send-btn');

    this.#autocompletion = new Autocompletiton(
      this.#nameField,
      unAssignedEmployees,
      document.getElementById('autocomplete-results'),
      this.#handleAcceptingAutoComp.bind(this)
    );

    this.#configureFormEventListeners();
  }

  #configureFormEventListeners() {
    this.#addEmployeeSlot.addEventListener('click', (e) => {
      e.stopPropagation();
      this.#showForm();
    });

    document.addEventListener('click', this.#hideForm.bind(this));
    document.addEventListener('keydown', (e) => {
      if (e.key === 'Escape') this.#hideForm();
    });

    this.#avatarField.addEventListener('change', this.#handleUploadImage.bind(this));

    this.#nameField.addEventListener('input', this.#handleNameInputChange.bind(this));

    this.#addEmployeeForm.addEventListener('submit', this.#handleFormSubmit.bind(this));
  }

  // ---------------------------------
  // GENERAL FORM FUNCTIOANLTIES
  // ---------------------------------
  #showForm(e) {
    if (this.#isFormShown) return;
    this.#isFormShown = true;

    this.#addEmployeeSlot.classList.add('form-shown');
    this.#nameField.focus();
  }

  #hideForm() {
    this.#isFormShown = false;
    this.#addEmployeeSlot.classList.remove('form-shown');
    this.#autocompletion.hideAutoCompletionList();
  }

  #disableShowingForm() {
    this.#addEmployeeSlot.style.pointerEvents = 'none';
  }

  #enableShowingForm() {
    this.#addEmployeeSlot.style.pointerEvents = 'auto';
  }

  #resetForm() {
    this.#avatarLabel.style.backgroundImage = 'url(images/add-employee.png)';
    this.#addEmployeeForm.reset();
  }

  #isFormValid() {
    const name = this.#nameField.value;
    if (name.trim() === '') return false;

    return true;
  }

  // ---------------------------------
  // HANDLERS
  // ---------------------------------
  #handleNameInputChange(e) {
    if (this.#isFormValid()) {
      this.#submitBtn.classList.remove('disabled');
    } else {
      this.#submitBtn.classList.add('disabled');
    }
  }

  #handleAcceptingAutoComp(selectedEmployeeId) {
    const employeeInfo = getEmployeeInfo(selectedEmployeeId);
    calender.insertEmployeeRow(employeeInfo);

    this.#submitBtn.classList.add('disabled');
    this.#hideForm();
    this.#resetForm();
  }

  #handleUploadImage(e) {
    if (!e.target.files.length) {
      this.#avatarLabel.style.backgroundImage = `url(/images/add-employee.png)`;

      return;
    }

    if (!validateUploadedImage(e.target.files[0])) {
      this.#avatarLabel.style.backgroundImage = `url(/images/add-employee.png)`;

      return alert('Please select an image file of max 5MB');
    }

    const reader = new FileReader();
    reader.readAsDataURL(e.target.files[0]);
    reader.addEventListener('load', () => {
      const uploadedImage = reader.result;

      this.#avatarLabel.style.backgroundImage = `url(${uploadedImage})`;
    });
  }

  async #handleFormSubmit(e) {
    e.preventDefault();
    if (!this.#isFormValid()) return window.alert('Please enter the NAME');

    try {
      this.#hideForm();
      this.#submitBtn.classList.add('disabled');
      this.#disableShowingForm();

      const formData = new FormData(this.#addEmployeeForm);
      const data = await createEmployee(formData);

      const newEmployee = {
        employeeId: data.data.member_id,
        employeeName: data.data.member_name,
        employeeRole: this.#roleField.value || 'Role Not entered',
        roleTextColor: data.data.role_text_color,
        roleBgColor: data.data.role_bg_color,
        avatarUrl: data.data.avatar,
      };

      allEmployees.push(newEmployee);
      calender.insertEmployeeRow(newEmployee, true);
    } catch (err) {
      console.log(err);
    } finally {
      this.#resetForm();
      this.#enableShowingForm();
    }
  }
}

new newEmployeeForm();
