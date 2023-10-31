class Overlay {
  #overlayDomEl = document.querySelector('#calender #overlay');

  #calenderHead = document.querySelector('#calender thead');
  #calenderBodyFirstRow = document.querySelector('#calender tbody tr');

  #calenderBodyFirstRowHeight = getComputedStyle(this.#calenderBodyFirstRow)
    .height;

  show() {
    this.#overlayDomEl.style.display = 'block';
    this.#overlayDomEl.style.height = this.#calcOverlayHeight();
    this.#overlayDomEl.style.top = this.#calcOverlayTopOffset();
  }

  hide() {
    this.#overlayDomEl.style.display = 'none';
  }

  #calcOverlayHeight() {
    const calenderBody = document.querySelector('#calender tbody');
    const calenderBodyHeight = getComputedStyle(calenderBody).height;

    const overlayHeight =
      parseFloat(calenderBodyHeight) -
      parseFloat(this.#calenderBodyFirstRowHeight);

    return `${overlayHeight}px`;
  }

  #calcOverlayTopOffset() {
    const calenderHeadHeight = getComputedStyle(this.#calenderHead).height;
    return `${
      parseFloat(this.#calenderBodyFirstRowHeight) +
      parseFloat(calenderHeadHeight)
    }px`;
  }
}

export default new Overlay();
