import os
import subprocess

def get_installed_tools():
    # Lấy danh sách các gói đã cài
    result = subprocess.run(['apt', 'list', '--installed'], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    lines = result.stdout.split('\n')[1:]  # Bỏ dòng đầu
    tools = []
    for line in lines:
        if '/' in line:
            tool_name = line.split('/')[0]
            tools.append(tool_name)
    return sorted(set(tools), key=lambda x: x.lower())

def get_tool_description(tool):
    try:
        # Lấy mô tả từ apt show
        result = subprocess.run(['apt', 'show', tool], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
        for line in result.stdout.split('\n'):
            if line.startswith("Description:"):
                return line.replace("Description:", "").strip()
    except Exception:
        return "Không có mô tả"
    return "Không có mô tả"

def main():
    tools = get_installed_tools()
    print(f"Tìm thấy {len(tools)} công cụ đã cài.")
    print("="*60)
    
    for tool in tools:
        desc = get_tool_description(tool)
        print(f"{tool:<30} - {desc}")

if __name__ == "__main__":
    main()
