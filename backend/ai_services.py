import os
import google.generativeai as genai
import json

# 从环境变量中获取API密钥
API_KEY = os.getenv("GEMINI_API_KEY")

genai.configure(api_key=API_KEY)

# 设置AI模型
model = genai.GenerativeModel('gemini-pro')

def get_initial_prompt():
    """
    返回固定的初始欢迎语和问题分类。
    """
    return {
        "response": "您好，我是您的AI法律顾问。请问您遇到了哪一类法律问题？",
        "options": ["劳动纠纷", "房屋租赁", "婚姻家事", "其他"]
    }

def get_ai_response(user_selection: str) -> dict:
    """
    接收用户的选项，调用Gemini Pro模型生成下一步的问题或建议。
    """
    try:
        # 我们让AI返回一个JSON格式的字符串，这样方便App解析并生成界面
        prompt = f"""你是一位专业的、富有同情心的AI法律顾问。你的任务是主动引导用户澄清他们的法律问题。请根据用户已经选择的选项，生成下一步需要询问用户的引导性问题，并提供3-5个最常见的相关选项。请务必以JSON格式返回，包含 'response' (你的提问) 和 'options' (选项列表)。
        
        用户的选择是：'{user_selection}'
        
        返回JSON示例：
        {{
            "response": "明白了，是劳动纠纷。具体是遇到了以下哪种情况呢？",
            "options": ["拖欠工资", "违法解雇", "工伤赔偿", "加班问题", "其他"]
        }}
        """
        
        response = model.generate_content(prompt)
        # 尝试将AI返回的纯文本解析为JSON对象
        return json.loads(response.text)
    except Exception as e:
        print(f"调用Gemini API或解析JSON时发生错误: {e}")
        # 如果AI返回的不是标准JSON或者API调用失败，我们返回一个备用回答
        return {
            "response": "抱歉，AI服务暂时无法连接或理解您的请求。您可以尝试用更详细的文字描述您的问题。",
            "options": []
        }
