import jquery from "jquery";

document.addEventListener("DOMContentLoaded", () => {
  let formElement = document.querySelector('#attachment_search');
  let formChanged = false;

  document.querySelectorAll('.select-filter').forEach(element => {
    jquery(element).selectpicker({
      width: 'fit',
      liveSearchPlaceholder: 'Search...',
      allowClear: true,
      dropdownAlignRight: 'auto'
    });

    jquery(element).on('changed.bs.select loaded.bs.select', function (e, clickedIndex, isSelected, previousValue) {
      let el = e.target,
          values = el.querySelectorAll('option:checked'),
          title = el.getAttribute('title'),
          text

      if (values.length > 1) {
        text = `${title}: ${values.length}`
      } else if (values.length === 1) {
        text = `${title}: ${values[0].innerText}`
      } else {
        text = `${title}`
      }

      el.parentElement.querySelector('.filter-option-inner-inner').innerText = text;
    });

    element.addEventListener('change', (e) => {
      formChanged = true;
    });
  })

  document.querySelectorAll('.dropdown.bootstrap-select.select-filter').forEach(element => {
    element.addEventListener('hidden.bs.dropdown', (e, s) => {
      if (formChanged) {
        formElement.submit();
      }
    });
  });

  document.querySelectorAll('.dropdown .bs-select-clear-selected').forEach(element => {
    element.addEventListener('click', (e, s) => {
      setTimeout(() => {
        if (formChanged) {
          formElement.submit();
        }
      }, 10)
    });
  });

  let itemsElement = document.querySelector('input[name="items"]');
  document.querySelectorAll('.select-perpage').forEach(element => {
    jquery(element).selectpicker({
      width: 'fit',
    });

    element.addEventListener('change', (e) => {
      itemsElement.value = e.target.value;
      formElement.submit();
    });
  });
});
