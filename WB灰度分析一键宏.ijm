// ============================================================
// WB 条带灰度值分析一键宏 (ImageJ / Fiji)
// 依据百度百家号教程的 8 步操作流程编写
// 运行后依次自动完成:
//   打开图像 -> 复制副本 -> 转 8-bit 灰度 -> 背景减除
//   -> 反色 -> 设置测量参数 -> 设置单位为像素
//   -> 交互式逐条带测量 -> 导出结果
// 说明:
//   * 原图会被复制一份用于分析, 原图不会被修改
//   * 背景减除默认 Rolling ball radius = 50 (亮背景)
//   * IntDen (积分灰度值) 是最终用于定量的关键数值
//   * 各条带请使用相同大小的矩形框, 以保证 Area 一致
//   * 结果默认自动保存到打开文件所在的文件夹
// ============================================================

// --- 第 1 步: 确保有图像, 若没有则弹出打开对话框 ---
if (nImages == 0) {
    open();
    if (nImages == 0) {
        exit("未打开任何图像");
    }
}

// 记录原图所在目录与名称, 用于之后自动保存结果
origDir = getDirectory("image");
origTitle = getTitle();

// 若原图上已有选区, 先取消, 避免复制时只复制选中区域
run("Select None");

// --- 复制一份进行分析, 保留原图 ---
run("Duplicate...", "title=WB_analysis");

// --- 第 2 步: 转换为 8-bit 灰度图像 ---
run("8-bit");

// --- 第 3 步: 背景减除, 消除背景影响 ---
// rolling=50 为教程默认值, 可按需修改
run("Subtract Background...", "rolling=50 light");

// --- 第 4 步: 反色, 背景变黑、条带变白 ---
run("Invert");

// --- 第 5 步: 设置测量参数 ---
// Area(面积), Mean(平均灰度), Min & max(最小最大灰度), IntDen(积分灰度)
run("Set Measurements...", "area mean min max integrated redirect=None decimal=3");

// --- 第 6 步: 设置测量单位为像素 ---
run("Set Scale...", "distance=0 known=0 pixel=1 unit=pixel");

// --- 第 7 步: 清空结果表, 交互式逐条带测量 ---
// 每次测量后矩形框会保留, 可整体拖动到下一个条带, 保证框选面积一致
run("Clear Results");
setTool("rectangle");
i = 0;
while (true) {
    if (i == 0) {
        waitForUser("请用矩形工具框选第 1 个条带, 然后点击 OK 进行测量。\n\n(可把此对话框移到一边后操作图像)");
    } else {
        waitForUser("请将矩形框拖动到第 " + (i + 1) + " 个条带, 然后点击 OK 进行测量。\n\n(在框内按住鼠标拖动即可整体移动; 不要点框线, 以保持框选面积不变)");
    }
    if (selectionType() == -1) {
        break;
    }
    run("Measure");
    i++;
    if (!getBoolean("已测量 " + i + " 个条带。\n是否继续测量下一个条带?")) {
        break;
    }
}

// --- 第 8 步: 导出结果 ---
if (nResults == 0) {
    showMessage("提示", "未测量到任何条带, 已退出。");
    exit();
}

// 结果默认自动保存到打开文件所在的文件夹
if (origDir != "") {
    saveDir = origDir;
} else {
    // 仅当图像没有文件路径(如剪贴板粘贴)时, 让用户选择文件夹
    saveDir = getDirectory("请选择结果保存的文件夹");
}

if (saveDir != "") {
    dotIdx = lastIndexOf(origTitle, ".");
    if (dotIdx > 0) {
        baseName = substring(origTitle, 0, dotIdx);
    } else {
        baseName = origTitle;
    }
    outPath = saveDir + baseName + "_WB灰度分析.xls";
    saveAs("Results", outPath);
    showMessage("完成", "共测量 " + i + " 个条带。\n结果已保存到:\n" + outPath + "\n\n(制表符分隔, 可直接用 Excel 打开)");
} else {
    showMessage("提示", "未选择保存位置。\n测量数据仍保留在 Results 表中, 可手动 File > Save As 另存。");
}
