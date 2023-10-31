import Cookies from 'js-cookie';
import PDFObject from 'pdfobject/pdfobject';
import './filters'
import { hideAllModals, initializeRevealPasswordButtons } from '../global'
import { Modal } from "bootstrap";

document.addEventListener("DOMContentLoaded", () => {
  const cookiesModal = document.querySelector('#cookies');
  if (cookiesModal) {
    if (Cookies.get('accept_cookies')) {
      cookiesModal.remove();
    } else {
      document.querySelector('#cookies button').addEventListener('click', () => {
        Cookies.set('accept_cookies', '1')
        cookiesModal.remove();
      });
    }
  }

  const backButton = document.querySelector('.container-back a');
  if (backButton) {
    backButton.addEventListener('click', e => {
      window.history.back();
      e.preventDefault();
    })
  }

  const pdfDisplayButton = document.querySelector('.pdf-display');
  if (pdfDisplayButton) {
    pdfDisplayButton.addEventListener('click', (e) => {
      const pdfElement = document.querySelector('.pdf-container');
      const documentUrl = pdfElement.getAttribute('data-document-url')
      pdfElement.classList.remove('d-none');
      PDFObject.embed(documentUrl, '.pdf-container');

      document.addEventListener('keydown', e => {
        if (e.key === 'Escape') {
          pdfElement.classList.add('d-none');
        }
      });

      e.preventDefault();
    })
  }

  document.querySelectorAll('.opened-modal .modal').forEach(el => {
     new Modal(el);
  })

  initializeRevealPasswordButtons();
});

document.addEventListener('keydown', e => {
  if (e.key === 'Escape') {
    hideAllModals();
  }
});
