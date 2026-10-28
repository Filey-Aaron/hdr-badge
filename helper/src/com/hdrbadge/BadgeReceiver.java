package com.hdrbadge;

import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;

/** 接收 root 脚本发来的弹标指令 */
public class BadgeReceiver extends BroadcastReceiver {

    @Override
    public void onReceive(Context context, Intent intent) {
        String type = intent.getStringExtra("type");
        if (type == null || type.isEmpty()) {
            type = "hdr";
        }
        Intent svc = new Intent(context, BadgeService.class);
        svc.setAction(BadgeService.ACTION_SHOW);
        svc.putExtra("type", type);
        if (android.os.Build.VERSION.SDK_INT >= 26) {
            context.startForegroundService(svc);
        } else {
            context.startService(svc);
        }
    }
}
