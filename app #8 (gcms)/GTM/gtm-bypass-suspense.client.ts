export default defineNuxtPlugin((NuxtApp) => {
  NuxtApp.hook('app:mounted', () => {
    setTimeout(() => {
      const shRoot = document.querySelector('#usercentrics-root')?.shadowRoot;
      if (shRoot) {
        const targetNode = shRoot.querySelector('div[data-nosnippet]');
        const config = { childList: true, subtree: true };
        const observer = new MutationObserver((mutationsList) => {
          for (const mutation of mutationsList) {
            if (mutation.type === 'childList')
              targetNode
                .querySelector('div[data-testid="uc-buttons-container"]')
                .querySelectorAll('button[role="button"]')
                .forEach((button) =>
                  button.addEventListener('click', () =>
                    window.location.reload(),
                  ),
                );
          }
        });
        observer.observe(targetNode, config);
      }
    }, 1000);
  });
});
