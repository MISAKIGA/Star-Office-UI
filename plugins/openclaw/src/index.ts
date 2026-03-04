/**
 * Star Office UI OpenClaw Plugin
 * 
 * 将 Agent 状态实时同步到 Star Office UI 像素办公室
 * 监听生命周期钩子: before_agent_start, agent_end, agent_error
 * 
 * 用法:
 *   import { register } from './src/index';
 *   
 *   // 在 OpenClaw 配置中启用插件
 *   // "plugins": {
 *   //   "star-office": {
 *   //     "enabled": true,
 *   //     "config": {
 *   //       "apiUrl": "http://localhost:5000",
 *   //       "apiToken": "your-api-token"
 *   //     }
 *   //   }
 *   // }
 */

export interface PluginConfig {
  apiUrl?: string;
  apiToken?: string;
  agentId?: string;
  agentName?: string;
  joinKey?: string;
}

export interface OpenClawAPI {
  pluginConfig: PluginConfig;
  logger?: {
    info: (msg: string) => void;
    warn: (msg: string) => void;
    error: (msg: string) => void;
  };
  on: (event: string, handler: (event: any) => void | Promise<void>) => void;
  registerService?: (service: {
    id: string;
    start: () => void | Promise<void>;
    stop: () => void | Promise<void>;
  }) => void;
}

/**
 * 状态推送函数 - 使用 /set_state 端点
 */
async function pushState(
  apiUrl: string, 
  apiToken: string, 
  state: string, 
  detail: string,
  logger?: OpenClawAPI['logger']
): Promise<boolean> {
  try {
    const resp = await fetch(`${apiUrl}/set_state`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-API-Token": apiToken,
      },
      body: JSON.stringify({ state, detail }),
    });

    if (!resp.ok) {
      const errText = await resp.text();
      logger?.warn(`star-office-plugin: push 失败: ${resp.status} - ${errText}`);
      return false;
    }

    logger?.info(`star-office-plugin: 状态更新 ${state} - ${detail}`);
    return true;
  } catch (err) {
    logger?.error(`star-office-plugin: 请求失败: ${String(err)}`);
    return false;
  }
}

/**
 * 插件注册函数 - OpenClaw 插件入口
 */
export function register(api: OpenClawAPI): void {
  const cfg = api.pluginConfig || {};
  
  const apiUrl = (cfg.apiUrl || "http://localhost:5000").replace(/\/$/, "");
  const apiToken = cfg.apiToken || "test-api-token-12345";

  api.logger?.info(`star-office-plugin: 启动 (${apiUrl})`);

  // -----------------------------------------------------------------------
  // 生命周期钩子
  // -----------------------------------------------------------------------

  api.on("before_agent_start", async () => {
    api.logger?.info("star-office-plugin: before_agent_start");
    await pushState(apiUrl, apiToken, "writing", "工作中...", api.logger);
  });

  api.on("agent_end", async (event) => {
    const success = event.success;
    const state = success === false ? "error" : "idle";
    const detail = success === false ? "执行失败" : "任务完成";
    
    api.logger?.info(`star-office-plugin: agent_end (${state})`);
    await pushState(apiUrl, apiToken, state, detail, api.logger);
  });

  api.on("agent_error", async () => {
    api.logger?.info("star-office-plugin: agent_error");
    await pushState(apiUrl, apiToken, "error", "执行出错", api.logger);
  });

  // -----------------------------------------------------------------------
  // Service (可选)
  // -----------------------------------------------------------------------

  api.registerService?.({
    id: "star-office",
    start: async () => {
      api.logger?.info("star-office-plugin: 服务启动");
      await pushState(apiUrl, apiToken, "idle", "待命中", api.logger);
    },
    stop: async () => {
      api.logger?.info("star-office-plugin: 服务停止");
      await pushState(apiUrl, apiToken, "idle", "离线", api.logger);
    },
  });
}

export default { register };
