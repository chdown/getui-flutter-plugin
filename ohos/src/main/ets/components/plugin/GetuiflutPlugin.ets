import {
  AbilityAware,
  AbilityPluginBinding,
  FlutterPlugin,
  FlutterPluginBinding,
  MethodCall,
  MethodCallHandler,
  MethodChannel,
  MethodResult,
  NewWantListener,
} from '@ohos/flutter_ohos';
import { AbilityConstant, common, Want } from '@kit.AbilityKit';
//引入个推SDK对外封装类
import PushManager, { GTCmdMessage, GTNotificationMessage, GTTransmitMessage } from '@getui/push';

/** GetuiflutPlugin **/
export default class GetuiflutPlugin implements FlutterPlugin, MethodCallHandler, AbilityAware, NewWantListener {
  private channel: MethodChannel | null = null;
  private appContext: common.Context | null = null;
  private uiContext: common.UIAbilityContext | null = null;
  private binding: AbilityPluginBinding | null = null

  constructor() {
  }

  getUniqueClassName(): string {
    return "GetuiflutPlugin"
  }

  onAttachedToEngine(binding: FlutterPluginBinding): void {
    this.channel = new MethodChannel(binding.getBinaryMessenger(), "getuiflut");
    this.channel.setMethodCallHandler(this)
    this.appContext = binding.getApplicationContext();
  }

  onDetachedFromEngine(binding: FlutterPluginBinding): void {
    if (this.channel != null) {
      this.channel.setMethodCallHandler(null)
    }
    this.appContext = null;
  }

  onAttachedToAbility(binding: AbilityPluginBinding): void {
    this.binding = binding
    this.uiContext = binding.getAbility().context;
    this.pushCallback();
    binding.addOnNewWantListener(this)
  }

  onDetachedFromAbility(): void {
    this.binding?.removeOnNewWantListener(this)
    this.binding = null
    this.uiContext = null;
  }

  onMethodCall(call: MethodCall, result: MethodResult): void {
    if (call.method == "getPlatformVersion") {
      result.success("hons")
    } else if (call.method == "initGetuiPush") {
      PushManager.initialize({
        context: this.uiContext,
        onSuccess: cid => {
          console.log("GetuiflutPlugin", "initGetuiPush，cid = " + cid);
        },
        onFailed: error => {
          console.log("GetuiflutPlugin", "initGetuiPush，error = " + error);
        }
      })
    } else if (call.method == "getClientId") {
      const clientId = PushManager.getClientId()
      result.success(clientId)
    } else {
      result.notImplemented()
    }
  }

  onNewWant(want: Want, launchParams: AbilityConstant.LaunchParam): void {
    // onCreate中的调用暂不定义
    if (want && want.parameters && want.parameters['gtdata']) {
      //注意这里的判断条件，在线点击通知回执和离线报表补全有区别
      if (!this.hasGttask(want.parameters['gtdata'])) {
        PushManager.setClickWant(want);
      }
    }
  }

  hasGttask(gtdata: ESObject): boolean {
    return gtdata['gttask'] !== undefined;
  }

  pushCallback(): void {
    PushManager.setPushCallback({
      // 接收 cid
      onReceiveClientId: clientId => {
        console.log("GetuiflutPlugin", "onReceiveClientId clientId = " + clientId);
        this.channel?.invokeMethod("onReceiveClientId", clientId);
      },
      //接收厂商token
      onReceiveDeviceToken: (token: string) => {
        console.log("GetuiflutPlugin", "onReceiveDeviceToken", "token = " + token);
        this.channel?.invokeMethod("onReceiveDeviceToken", token);
      },
      // cid 离线上线通知
      onReceiveOnlineState: (onLine: boolean) => {
        console.log("GetuiflutPlugin", "onReceiveOnlineState", "onLine = " + onLine);
        this.channel?.invokeMethod("onReceiveOnlineState", onLine);
      },
      //命令相应回复
      onReceiveCommandResult: (message: GTCmdMessage) => {
        console.log("GetuiflutPlugin", "onReceiveCommandResult", "cmd = " + JSON.stringify(message));
        const _result: Map<string, ESObject> = new Map();
        _result.set("appId", message.appId);
        _result.set("pkgName", message.pkgName);
        _result.set("clientId", message.clientId);
        _result.set("action", message.action);
        this.channel?.invokeMethod("onReceiveCommandResult", _result);
      },
      //sdk 收到透传消息
      onReceiveMessageData: (message: GTTransmitMessage) => {
        console.log("GetuiflutPlugin", "onReceiveMessageData", "cmd = " + JSON.stringify(message));
        const _result: Map<string, ESObject> = new Map();
        _result.set("appId", message.appId);
        _result.set("pkgName", message.pkgName);
        _result.set("clientId", message.clientId);
        _result.set("taskId", message.taskId);
        _result.set("messageId", message.messageId);
        _result.set("payloadId", message.payloadId);
        _result.set("payload", message.payload);
        _result.set("isOffline", message.isOffline);
        this.channel?.invokeMethod("onReceiveMessageData", _result);
      },
      //通知到达回调
      onNotificationMessageArrived: (message: GTNotificationMessage) => {
        console.log("GetuiflutPlugin", "onNotificationMessageArrived", "message = " + JSON.stringify(message));
        const _result: Map<string, ESObject> = new Map();
        _result.set("appId", message.appId);
        _result.set("pkgName", message.pkgName);
        _result.set("clientId", message.clientId);
        _result.set("taskId", message.taskId);
        _result.set("title", message.title);
        _result.set("content", message.content);
        _result.set("payload", message.payload);
        _result.set("url", message.url);
        _result.set("intentUri", message.intentUri);
        this.channel?.invokeMethod("onNotificationMessageArrived", _result);
      },
      //通知点击回调, 需要配合PushManager.setClickWant(want)使用
      onNotificationMessageClicked: (message: GTNotificationMessage) => {
        console.log("GetuiflutPlugin", "onNotificationMessageClicked", "message = " + JSON.stringify(message));
        const _result: Map<string, ESObject> = new Map();
        _result.set("appId", message.appId);
        _result.set("pkgName", message.pkgName);
        _result.set("clientId", message.clientId);
        _result.set("taskId", message.taskId);
        _result.set("title", message.title);
        _result.set("content", message.content);
        _result.set("payload", message.payload);
        _result.set("url", message.url);
        _result.set("intentUri", message.intentUri);
        this.channel?.invokeMethod("onNotificationMessageClicked", _result);
      },
    })
  }
}