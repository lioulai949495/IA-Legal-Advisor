import os
import google.generativeai as genai
import json

# 从环境变量中获取API密钥
API_KEY = os.getenv("GOOGLE_API_KEY") # 确保使用正确的环境变量名

genai.configure(api_key=API_KEY)

# 设置AI模型
model = genai.GenerativeModel("gemini-1.5-flash")

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
        # 优化后的Prompt，更强硬地要求返回JSON
        prompt = f"""你是一位专业的AI法律顾问。你的任务是主动引导用户澄清问题。根据用户的选择，生成引导性问题和3-5个选项。你的回答必须且只能是一个严格的、不包含任何额外文本或解释的JSON对象。JSON对象必须包含'response'(字符串)和'options'(字符串列表)两个键。
        
        用户的选择是：'{user_selection}'
        
        JSON输出示例：
        {{
            "response": "明白了，是劳动纠纷。具体是遇到了以下哪种情况呢？",
            "options": ["拖欠工资", "违法解雇", "工伤赔偿", "加班问题", "其他"]
        }}
        """
        
        response = model.generate_content(prompt)
        raw_text = response.text.strip()

        # 增加安全检查，确保返回的文本看起来像JSON
        if not raw_text.startswith('{') or not raw_text.endswith('}'):
            print(f"AI返回了非JSON格式的文本: {raw_text}")
            raise ValueError("AI response is not in JSON format")

        return json.loads(raw_text)
    except Exception as e:
        print(f"调用Gemini API或解析JSON时发生错误: {e}")
        return {
            "response": f"抱歉，AI在处理‘{user_selection}’时遇到问题，无法生成下一步选项。请尝试用更详细的文字描述您的问题。",
            "options": []
        }
