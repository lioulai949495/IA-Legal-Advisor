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
        # 将所有上下文信息整合进Prompt
        prompt = f"""你是一位专业的AI法律顾问。你的任务是基于用户提供的明确上下文，进行有针对性的引导式提问或提供初步建议。你的回答必须且只能是一个严格的JSON对象，包含'response'(字符串)和'options'(字符串列表)两个键。如果提供建议，options可以为空列表。
        
        --- 用户上下文 ---
        法律分类：{category}
        用户角色：{role}
        具体问题：{subtype}
        用户的初步描述：{message}
        -------------------
        
        请根据以上信息，开始进行对话。
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
            "response": f"抱歉，AI在处理您的问题时遇到错误。请尝试重新开始或用文字详细描述您的问题。",
            "options": []
        }
