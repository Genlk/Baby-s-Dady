/**
 * 鸿蒙 ArkTS API 客户端参考实现
 * 与 Flutter 版 mobile/lib/services/api_service.dart 功能一致
 *
 * 使用方式：
 * 1. 在 DevEco Studio 中创建 HarmonyOS 工程
 * 2. 将本文件复制到 entry/src/main/ets/services/ApiService.ets
 * 3. 在 module.json5 中声明 ohos.permission.INTERNET 权限
 */

import http from '@ohos.net.http';

export interface AnalysisResult {
  behavior: string;
  behavior_cn: string;
  confidence: number;
  alert: boolean;
  alert_message: string;
  movement: number;
  torso_angle: number;
}

export class ApiService {
  private baseUrl: string = 'http://192.168.1.100:8000';

  setBaseUrl(url: string): void {
    this.baseUrl = url.replace(/\/+$/, '');
  }

  async checkHealth(): Promise<boolean> {
    try {
      const httpRequest = http.createHttp();
      const response = await httpRequest.request(`${this.baseUrl}/health`, {
        method: http.RequestMethod.GET,
        connectTimeout: 5000,
        readTimeout: 5000,
      });
      httpRequest.destroy();
      return response.responseCode === 200;
    } catch (e) {
      return false;
    }
  }

  async analyzeImage(imageBuffer: ArrayBuffer): Promise<AnalysisResult> {
    const boundary = '----BabyMonitor' + Date.now();
    const body = this.buildMultipartBody(boundary, imageBuffer, 'capture.jpg');

    const httpRequest = http.createHttp();
    const response = await httpRequest.request(
      `${this.baseUrl}/api/v1/analyze/image`,
      {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': `multipart/form-data; boundary=${boundary}`,
        },
        extraData: body,
        connectTimeout: 30000,
        readTimeout: 30000,
      }
    );
    httpRequest.destroy();

    if (response.responseCode !== 200) {
      throw new Error(`分析失败: ${response.responseCode}`);
    }
    return JSON.parse(response.result as string) as AnalysisResult;
  }

  private buildMultipartBody(
    boundary: string,
    fileData: ArrayBuffer,
    filename: string
  ): string {
    const parts: string[] = [];
    parts.push(`--${boundary}`);
    parts.push(`Content-Disposition: form-data; name="return_image"`);
    parts.push('');
    parts.push('true');
    parts.push(`--${boundary}`);
    parts.push(`Content-Disposition: form-data; name="file"; filename="${filename}"`);
    parts.push('Content-Type: image/jpeg');
    parts.push('');
    // 注意：实际生产中需用 ArrayBuffer 拼接，此处为结构参考
    return parts.join('\r\n');
  }
}
