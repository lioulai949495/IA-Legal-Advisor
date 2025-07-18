# flow_config.py

# 定义每个分类对应的角色选项
ROLES = {
    "买卖纠纷": ["我是买家", "我是卖家"],
    "借贷纠纷": ["我是出借人(债权人)", "我是借款人(债务人)"],
    "婚姻纠纷": ["我想起诉离婚", "我被起诉离婚", "婚内财产/债务问题"],
    "所有权纠纷": ["我是合法占有人", "我是所有权主张人"],
    "劳动纠纷": ["我是员工", "我是公司"], # 新增
}

# 定义每个分类和角色组合下的细分类型
SUBTYPES = {
    # --- 买卖纠纷细化 ---
    "买卖纠纷": {
        "我是买家": ["产品质量不合格", "卖家虚假宣传", "卖家迟迟不发货", "定金/预付款问题"],
        "我是卖家": ["买家无故拒收", "买家拖欠货款", "买家恶意退货/差评", "产品被仿冒侵权"],
    },
    # --- 借贷纠纷细化 ---
    "借贷纠纷": {
        "我是出借人(债权人)": ["借款到期不还", "利息计算/支付问题", "找不到借款人", "担保人责任问题"],
        "我是借款人(债务人)": ["利息过高(高利贷)", "还款方式/期限争议", "借条/合同内容有误", "被暴力催收"],
    },
    # --- 婚姻纠纷细化 ---
    "婚姻纠纷": {
        "我想起诉离婚": ["子女抚养权归属", "子女抚养费数额", "婚后财产分割", "对方存在过错(家暴/出轨/赌博等)"],
        "我被起诉离婚": ["我不同意离婚", "如何争取抚养权", "如何保护我的财产", "对方伪造债务"],
        "婚内财产/债务问题": ["一方转移/隐藏财产", "婚前财产的界定", "夫妻共同债务的认定", "要求分割共同财产"],
    },
    # --- 所有权纠纷细化 ---
    "所有权纠纷": {
        "我是合法占有人": ["他人主张物品归其所有", "物品被盗/被抢占", "善意取得的物品"],
        "我是所有权主张人": ["我的物品被他人占有", "确认不动产/车辆所有权", "共有财产的分割"],
    },
    # --- 劳动纠纷细化 (新增) ---
    "劳动纠纷": {
        "我是员工": ["工资/加班费拖欠", "违法解除/辞退", "工伤认定/赔偿", "未签订劳动合同", "竞业限制/保密协议"],
        "我是公司": ["员工严重违反规章制度", "员工申请劳动仲裁", "经济性裁员流程", "员工离职/交接问题"],
    }
}

