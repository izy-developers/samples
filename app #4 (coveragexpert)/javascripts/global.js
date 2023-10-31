import { Modal } from 'bootstrap'

function createOrUpdateElement(id, content) {
  let el = document.querySelector("#" + id)
  if(el) {
    el.innerHTML = content;
  } else {
    el = document.createElement('div');
    el.id = id;
    el.innerHTML = content;
    document.body.appendChild(el);
  }
}

export function showModal(id, content, hideModals = true) {
  if(hideModals) {
    hideAllModals();
  }

  createOrUpdateElement(id, content);

  let modal = new Modal(document.querySelector(`#${id} .modal`));
  modal.show();

  let autofocusField = document.querySelector(`#${id} input[autofocus]`);
  if (autofocusField) {
    autofocusField.focus();
  }

  document.querySelectorAll(`#${id} [data-dismiss="modal"]`).forEach(item => {
    item.addEventListener('click', event => {
      hideAllModals();
    })
  })

  initializeRevealPasswordButtons()
  initializeFundsSelector()
  initializeCheckoutJS()
}

export function hideAllModals() {
  document.querySelectorAll('.modal').forEach(item => {
    let modal = Modal.getInstance(item);
    modal.hide();
  })
}

export function initializeRevealPasswordButtons() {
  document.querySelectorAll('.toggle-password').forEach((element) => {
    element.addEventListener('click', (e) => {
      var input = document.querySelector(element.getAttribute('data-toggle'))

      if (input.getAttribute('type') == 'password') {
        input.setAttribute("type", "text");
      } else {
        input.setAttribute("type", "password");
      }

      input.focus()
      e.preventDefault()
    })
  });
}

export function initializeFundsSelector() {
  document.querySelectorAll('.funds-selector').forEach((element) => {
    let plusButton = element.querySelector('button.button-plus')
    let minusButton = element.querySelector('button.button-minus')
    let input = element.querySelector('input')

    let inputFilter = value => /^\d*\.?\d*$/.test(value);

    plusButton.addEventListener('click', () => {
      input.value = (parseInt(input.value) + 1).toFixed(2);
    });

    minusButton.addEventListener('click', () => {
      input.value = (parseInt(input.value) - 1).toFixed(2);
    });

    ["input", "keydown", "keyup", "mousedown", "mouseup", "select", "contextmenu", "drop"].forEach(function(event) {
      input.addEventListener(event, function() {
        if (inputFilter(this.value)) {
          this.oldValue = this.value;
          this.oldSelectionStart = this.selectionStart;
          this.oldSelectionEnd = this.selectionEnd;
        } else if (this.hasOwnProperty("oldValue")) {
          this.value = this.oldValue;
          this.setSelectionRange(this.oldSelectionStart, this.oldSelectionEnd);
        } else {
          this.value = "";
        }
      });
    });
  });
}

export function initializeCheckoutJS() {
  if(typeof(Stripe) === 'undefined') {
    return
  }

  const stripe = Stripe(process.env.STRIPE_PUBLIC_KEY);

  let checkoutButton = document.getElementById('checkout-button');
  let input = document.getElementById('checkout-input');
  let type = document.getElementById('checkout-type');
  let attachmentId = document.getElementById('checkout-attachment-id');

  checkoutButton.addEventListener('click', function() {
    // Create a new Checkout Session using the server-side endpoint you
    // created in step 3.
    fetch('/create-checkout', {
      method: 'POST',
      body: JSON.stringify({
        amount: input.value,
        type: type.value,
        attachment_id: attachmentId?.value,
      })
    })
      .then(function(response) {
        return response.json();
      })
      .then(function(session) {
        return stripe.redirectToCheckout({ sessionId: session.id });
      })
      .then(function(result) {
        // If `redirectToCheckout` fails due to a browser or network
        // error, you should display the localized error message to your
        // customer using `error.message`.
        if (result.error) {
          alert(result.error.message);
        }
      })
      .catch(function(error) {
        console.error('Error:', error);
      });
  });
}
