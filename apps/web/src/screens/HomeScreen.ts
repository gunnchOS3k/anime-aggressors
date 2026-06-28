import {
  MAIN_MENU_LABS,
  MAIN_MENU_PLAYER,
  MAIN_MENU_PRIMARY,
  MAIN_MENU_SECONDARY,
} from "../ui/mainMenuConfig.ts";
import { renderHomeMarkup } from "./homeScreenMarkup.ts";
import { createMenuNavigation, type MenuNavigationController } from "../input/menuNavigation.ts";
import { createMainMenuSceneRenderer, type MainMenuSceneRenderer } from "../renderer-three/menu/MainMenuSceneRenderer.ts";

export type HomeScreenHandle = {
  dispose: () => void;
  getNavigation: () => MenuNavigationController | null;
  getSceneRenderer: () => MainMenuSceneRenderer | null;
};

export function mountHomeScreen(container: HTMLElement): HomeScreenHandle {
  container.innerHTML = renderHomeMarkup();
  container.classList.add("arena-hub-root");

  let scene: MainMenuSceneRenderer | null = null;
  let nav: MenuNavigationController | null = null;

  const canvas = container.querySelector<HTMLCanvasElement>("#menu-scene-canvas");
  if (canvas) {
    scene = createMainMenuSceneRenderer(canvas);
    scene.start();

    const onResize = () => {
      scene?.resize(canvas.clientWidth, canvas.clientHeight);
    };
    onResize();
    window.addEventListener("resize", onResize);

    const hub = container.querySelector(".arena-hub");
    nav = createMenuNavigation({
      root: hub as HTMLElement,
      primary: MAIN_MENU_PRIMARY,
      carousel: MAIN_MENU_SECONDARY,
      player: MAIN_MENU_PLAYER,
      labs: MAIN_MENU_LABS,
    });

    return {
      dispose: () => {
        window.removeEventListener("resize", onResize);
        nav?.dispose();
        scene?.dispose();
        scene = null;
        nav = null;
        container.innerHTML = "";
        container.classList.remove("arena-hub-root");
      },
      getNavigation: () => nav,
      getSceneRenderer: () => scene,
    };
  }

  nav = createMenuNavigation({
    root: container.querySelector(".arena-hub") as HTMLElement,
    primary: MAIN_MENU_PRIMARY,
    carousel: MAIN_MENU_SECONDARY,
    player: MAIN_MENU_PLAYER,
    labs: MAIN_MENU_LABS,
  });

  return {
    dispose: () => {
      nav?.dispose();
      nav = null;
      container.innerHTML = "";
      container.classList.remove("arena-hub-root");
    },
    getNavigation: () => nav,
    getSceneRenderer: () => scene,
  };
}

export { renderHomeMarkup } from "./homeScreenMarkup.ts";
