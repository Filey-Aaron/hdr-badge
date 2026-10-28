package com.hdrbadge;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.Service;
import android.content.Intent;
import android.graphics.PixelFormat;
import android.os.Build;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.view.Gravity;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;

/** 悬浮窗服务：在右上角绘制 HDR / 杜比视界标识，3 秒后淡出 */
public class BadgeService extends Service {

    public static final String ACTION_SHOW = "com.hdrbadge.action.SHOW";

    private WindowManager wm;
    private View badgeView;
    private final Handler handler = new Handler(Looper.getMainLooper());
    private Runnable hideTask;

    @Override
    public void onCreate() {
        super.onCreate();
        wm = (WindowManager) getSystemService(WINDOW_SERVICE);
        if (Build.VERSION.SDK_INT >= 26) {
            NotificationChannel ch = new NotificationChannel(
                    "hdrbadge", "HDR Badge", NotificationManager.IMPORTANCE_MIN);
            ch.setShowBadge(false);
            NotificationManager nm = getSystemService(NotificationManager.class);
            if (nm != null) nm.createNotificationChannel(ch);
            Notification n = new Notification.Builder(this, "hdrbadge")
                    .setContentTitle("HDR Badge")
                    .setSmallIcon(android.R.drawable.ic_menu_view)
                    .setPriority(Notification.PRIORITY_MIN)
                    .build();
            startForeground(1001, n);
        }
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null && ACTION_SHOW.equals(intent.getAction())) {
            String type = intent.getStringExtra("type");
            showBadge(type == null ? "hdr" : type);
        }
        return START_NOT_STICKY;
    }

    private void showBadge(String type) {
        // 若已有标在显示，先移除
        if (badgeView != null) {
            try { wm.removeView(badgeView); } catch (Exception ignored) {}
            badgeView = null;
        }
        if (hideTask != null) {
            handler.removeCallbacks(hideTask);
        }

        int resId = "dolby".equals(type)
                ? R.drawable.dolby_vision_logo
                : R.drawable.hdr_logo;

        ImageView iv = new ImageView(this);
        iv.setImageResource(resId);
        // 用图片原始像素尺寸绘制，避免被当成 dp 二次缩放导致糊
        android.graphics.drawable.BitmapDrawable bd = (android.graphics.drawable.BitmapDrawable) iv.getDrawable();
        iv.setScaleType(ImageView.ScaleType.CENTER);
        iv.setAdjustViewBounds(true);
        int bw = bd.getBitmap().getWidth();
        int bh = bd.getBitmap().getHeight();

        int type_ = Build.VERSION.SDK_INT >= 26
                ? WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                : WindowManager.LayoutParams.TYPE_SYSTEM_ALERT;

        WindowManager.LayoutParams lp = new WindowManager.LayoutParams(
                bw, bh,
                type_,
                WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                        | WindowManager.LayoutParams.FLAG_NOT_TOUCHABLE
                        | WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN
                        | WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                PixelFormat.TRANSLUCENT);
        lp.gravity = Gravity.TOP | Gravity.END;
        lp.x = 60;
        lp.y = 50;

        try {
            wm.addView(iv, lp);
            badgeView = iv;
            iv.setAlpha(0f);
            iv.animate().alpha(1f).setDuration(250).start();

            hideTask = () -> {
                if (badgeView != null) {
                    badgeView.animate().alpha(0f).setDuration(400)
                            .withEndAction(() -> {
                                try { wm.removeView(badgeView); } catch (Exception ignored) {}
                                badgeView = null;
                            }).start();
                }
            };
            handler.postDelayed(hideTask, 3000);
        } catch (Exception e) {
            badgeView = null;
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }
}
