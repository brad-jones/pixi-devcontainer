import * as fs from "https://deno.land/std@0.210.0/fs/mod.ts";
import * as path from "https://deno.land/std@0.210.0/path/mod.ts";
import { paramCase } from "https://deno.land/x/case@2.2.0/mod.ts";

export const __filename = (meta: ImportMeta) => path.fromFileUrl(meta.url);
export const __dirname = (meta: ImportMeta) =>
  path.dirname(path.fromFileUrl(meta.url));

export const devContainerTest = (
  t: Deno.TestContext,
  templateId: string,
  templateOptions: Record<string, string>,
  commands: string[][],
) =>
  goDefer(async (defer) => {
    const workspaceDir = await createTmpWorkspace(templateId, templateOptions);
    defer(() => Deno.remove(workspaceDir, { recursive: true }));

    const containerId = paramCase(t.name);
    await startDevContainer(containerId, workspaceDir);
    defer(() => rmDevContainer(containerId));

    for (const command of commands) {
      await execInDevContainer(
        containerId,
        workspaceDir,
        command[0],
        command.slice(1),
      );
    }
  });

export async function createTmpWorkspace(
  templateId: string,
  templateOptions: Record<string, string>,
): Promise<string> {
  // Create a tmp dir & copy the template src into it
  const srcDir = path.join(__dirname(import.meta), "src", templateId);
  const workspaceDir = await Deno.makeTempDir();
  await fs.copy(srcDir, workspaceDir, { overwrite: true });

  // Copy the features into the same temp dir
  const featuresDir = path.join(__dirname(import.meta), "../features/src");
  await fs.copy(
    featuresDir,
    path.join(workspaceDir, ".devcontainer/features"),
    {
      overwrite: true,
    },
  );

  // Update any feature oci references with local paths instead
  const configPath = path.join(workspaceDir, ".devcontainer/devcontainer.json");
  const config = JSON.parse(await Deno.readTextFile(configPath)) as {
    features: Record<string, unknown>;
  };
  const newFeatures: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(config.features)) {
    const matches = k.match(
      /ghcr\.io\/brad-jones\/pixi-devcontainer\/(.*?):.*/,
    );
    if (matches) {
      newFeatures[`./features/${matches[1]}`] = v;
    } else {
      newFeatures[k] = v;
    }
  }
  config.features = newFeatures;
  await Deno.writeTextFile(configPath, JSON.stringify(config));

  // Replace all template options with the given values
  const jobs: Promise<void>[] = [];
  const replacements = Object.entries(templateOptions)
    .map(([k, v]) => ({ s: `\${templateOption:${k}}`, r: v }));
  for await (const dirEntry of fs.walk(workspaceDir)) {
    if (!dirEntry.isFile) continue;
    jobs.push(replaceInFile(dirEntry.path, replacements));
  }
  await Promise.all(jobs);

  return workspaceDir;
}

export async function getDefaultOptions(
  templateId: string,
): Promise<Record<string, string>> {
  const srcDir = path.join(__dirname(import.meta), "src", templateId);

  const tpl = JSON.parse(
    await Deno.readTextFile(
      path.join(srcDir, "devcontainer-template.json"),
    ),
  );

  if (!tpl.options) return {};

  return Object.fromEntries(
    Object.entries(tpl.options as Record<string, { default: string }>)
      .map(([k, v]) => [k, v.default]),
  );
}

export async function startDevContainer(id: string, workspaceDir: string) {
  const cmd = new Deno.Command("devcontainer", {
    args: [
      "up",
      "--remove-existing-container",
      "--id-label",
      `test-container=${id}`,
      "--workspace-folder",
      workspaceDir,
    ],
    stdout: "inherit",
    stderr: "inherit",
  });

  const { code } = await cmd.output();
  if (code !== 0) {
    throw new Error(
      `failed to start devcontainer with id: ${id} in dir: ${workspaceDir}`,
    );
  }
}

export async function rmDevContainer(id: string) {
  const { code, stdout } = await new Deno.Command("docker", {
    args: ["container", "ls", "-f", `label=test-container=${id}`, "-q"],
  }).output();

  if (code !== 0) {
    throw new Error(
      `failed to list docker containers with id: ${id}`,
    );
  }

  const actualContainerId = new TextDecoder().decode(stdout).trim();

  const rmResult = await new Deno.Command("docker", {
    args: ["rm", "-f", actualContainerId],
    stdout: "inherit",
    stderr: "inherit",
  }).output();

  if (rmResult.code !== 0) {
    throw new Error(
      `failed to remove docker container with id: ${actualContainerId}`,
    );
  }
}

export async function execInDevContainer(
  id: string,
  workspaceDir: string,
  command: string,
  args: string[],
) {
  const cmd = new Deno.Command("devcontainer", {
    args: [
      "exec",
      "--id-label",
      `test-container=${id}`,
      "--workspace-folder",
      workspaceDir,
      command,
      ...args,
    ],
    stdout: "inherit",
    stderr: "inherit",
  });

  const { code } = await cmd.output();

  if (code !== 0) {
    throw new Error(
      `failed to exec '${command} ${args.join(" ")}' inside ${id}`,
    );
  }
}

export async function replaceInFile(
  path: string,
  replacements: { s: string | RegExp; r: string }[],
) {
  let dat = await Deno.readTextFile(path);
  for (const { s, r } of replacements) {
    dat = dat.replaceAll(s, r);
  }
  await Deno.writeTextFile(path, dat);
}

export async function goDefer<T>(
  func: (defer: (deferred: () => Promise<void> | void) => void) => Promise<T>,
): Promise<T> {
  const deferredJobs: (() => Promise<void> | void)[] = [];
  const defer = (deferred: () => Promise<void> | void) =>
    deferredJobs.push(deferred);

  let result: T;
  try {
    result = await func(defer);
  } finally {
    while (deferredJobs.length > 0) {
      await deferredJobs.pop()!();
    }
  }

  return result;
}

export function goDeferSync<T>(
  func: (defer: (deferred: () => void) => void) => T,
): T {
  const deferredJobs: (() => void)[] = [];
  const defer = (deferred: () => void) => deferredJobs.push(deferred);

  let result;
  try {
    result = func(defer);
  } finally {
    while (deferredJobs.length > 0) {
      deferredJobs.pop()!();
    }
  }

  return result;
}
