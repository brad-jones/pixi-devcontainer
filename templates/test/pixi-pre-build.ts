import { devContainerTest, getDefaultOptions } from "../test-utils.ts";

const TEMPLATE_ID = "pixi-pre-build";

Deno.test("default-template-options", async (t) =>
  devContainerTest(t, TEMPLATE_ID, await getDefaultOptions(TEMPLATE_ID), [
    ["task", "--version"],
  ]));

Deno.test("base-debian", (t) =>
  devContainerTest(t, TEMPLATE_ID, {
    baseImg: "mcr.microsoft.com/devcontainers/base:debian",
    pixiVersion: "latest",
  }, [
    ["task", "--version"],
  ]));

Deno.test("base-ubuntu", (t) =>
  devContainerTest(t, TEMPLATE_ID, {
    baseImg: "mcr.microsoft.com/devcontainers/base:ubuntu",
    pixiVersion: "latest",
  }, [
    ["task", "--version"],
  ]));
