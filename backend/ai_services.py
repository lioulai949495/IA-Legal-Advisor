import os
import google.generativeai as genai
import json
from flow_config import ROLES, SUBTYPES # 导入我们预设的流程

# 从环境变量中获取API密钥
API_KEY = os.getenv("GOOGLE_API_KEY")

genai.configure(api_key=API_KEY)

# 设置AI模型
model = genai.GenerativeModel("gemini-1.5-flash")

def get_initial_categories():
    """
    返回固定的初始法律问题分类。
    """
    return {
        "response": "您好，我是您的AI法律顾问。请问您遇到了哪一类法律问题？",
        "options": list(ROLES.keys()) # 从配置中动态获取key
    }

def get_roles_for_category(category: str):
    """
    根据分类返回固定的角色选项。
    """
    roles = ROLES.get(category, [])
    return {
        "response": f"好的，关于‘{category}’，请问您的身份是？",
        "options": roles
    }

def get_subtypes_for_role(category: str, role: str):
    """
    根据分类和角色返回固定的子类型选项。
    """
    subtypes = SUBTYPES.get(category, {}).get(role, [])
    return {
        "response": f"明白了。更具体一点，是关于哪方面的问题呢？",
        "options": subtypes
    }

def get_ai_response(category: str, role: str, subtype: str, message: str) -> dict:
    """
    接收所有上下文，调用AI进行最终的、有针对性的对话。
    """
    try:
        # --- 高度结构化的新Prompt ---
        prompt = f"""你是一位专业的、冷静的AI法律顾问。你的任务是基于用户提供的明确上下文，给出一份高度结构化的、可行动的法律分析报告。你的回答必须且只能是一个严格的JSON对象。

        --- 用户上下文 ---
        法律分类：{category}
        用户角色：{role}
        具体问题：{subtype}
        用户的初步描述：{message}
        -------------------

        --- 你的任务 ---
        请严格按照以下四个步骤生成你的报告，并将其组织在一个JSON对象中，该JSON对象必须包含 `analysis_report` 键，其值为另一个包含以下四个键的JSON对象：

        1.  `applicable_laws`: 一个字符串。精确列出与本案最直接相关的1-3条法律法规条款的原文。
        2.  `success_rate_analysis`: 一个JSON对象。包含两个键：
            - `rate`: 一个整数，代表你预估的胜诉率（0-100之间）。
            - `reason`: 一个字符串，用1-2句话简要说明你给出该胜诉率的核心理由。
        3.  `action_suggestion`: 一个字符串。根据你给出的胜诉率，执行以下分支逻辑：
            - 如果胜诉率大于等于60，你的建议应以“建议积极准备诉讼”开头。
            - 如果胜诉率低于60，你的建议应以“建议优先考虑调解或和解”开头，并简要说明诉讼的风险。
        4.  `next_steps`: 一个JSON对象。提供后续行动指南，包含两个键：
            - `process_guidance`: 一个字符串，简要描述下一步的诉讼流程（例如：1.准备起诉状和证据；2.去法院立案...）。
            - `document_templates`: 一个字符串，列出所需的核心文书，例如：“起诉状、证据清单、财产保全申请书”。

        --- JSON输出示例 ---
        {{
            "analysis_report": {{
                "applicable_laws": "《中华人民共和国劳动合同法》第八十二条：用人单位自用工之日起超过一个月不满一年未与劳动者订立书面劳动合同的，应当向劳动者每月支付二倍的工资。",
                "success_rate_analysis": {{
                    "rate": 85,
                    "reason": "您有清晰的打卡记录和工资流水，且未签订劳动合同的事实明确，证据链较为完整。"
                }},
                "action_suggestion": "建议积极准备诉讼。根据法律规定，您获得双倍工资赔偿的请求有很高的支持可能性。",
                "next_steps": {{
                    "process_guidance": "1. 准备劳动仲裁申请书；2. 整理您的打卡记录、工资流水等证据材料；3. 向当地劳动人事争议仲裁委员会提交申请。",
                    "document_templates": "劳动仲裁申请书、证据清单"
                }}
            }}
        }}
        """
        
        response = model.generate_content(prompt)
        raw_text = response.text.strip()

        if raw_text.startswith("```json"):
            raw_text = raw_text[7:-3].strip()

        if not raw_text.startswith('{') or not raw_text.endswith('}'):
            print(f"AI返回了非JSON格式的文本: {raw_text}")
            raise ValueError("AI response is not in JSON format")

        return json.loads(raw_text)
    except Exception as e:
        print(f"调用Gemini API或解析JSON时发生错误: {e}")
        return {
            "error": f"抱歉，AI在分析您的问题时遇到内部错误。请稍后重试。"
        }
