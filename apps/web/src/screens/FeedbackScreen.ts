export function mountFeedbackScreen(root: HTMLElement): void {
  root.innerHTML = `
    <div class="screen feedback-screen">
      <div class="screen-toolbar">
        <button type="button" id="fb-back" class="btn-tertiary">← Main Menu</button>
        <h2>Playtest Feedback</h2>
      </div>
      <p>Help us improve Anime Aggressors! Copy the template below or open the full form on GitHub.</p>
      <ol class="playtest-steps">
        <li>Open the web build</li>
        <li>Click <strong>Create Fighter</strong></li>
        <li>Make a fighter (size + ROYGBIV color)</li>
        <li>Click <strong>Play Match</strong></li>
        <li>Try <strong>Impact Dummy Derby</strong></li>
        <li>Fill out the feedback form</li>
      </ol>
      <a class="btn-primary" href="https://github.com/gunnchOS3k/anime-aggressors/blob/main/docs/playtest/feedback-form.md" target="_blank" rel="noopener">
        Open Feedback Form
      </a>
      <a class="btn-secondary" href="https://github.com/gunnchOS3k/anime-aggressors/blob/main/docs/playtest/PC_PLAYTEST_GUIDE.md" target="_blank" rel="noopener">
        PC Playtest Guide
      </a>
    </div>
  `;
  root.querySelector("#fb-back")?.addEventListener("click", () => {
    window.location.hash = "#/";
  });
}
