#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import re

def clean_json_file(input_path, output_path):
    """
    清理JSON文件，去除注释，并保存为规范的JSON格式
    """
    print(f"正在处理文件: {input_path}")
    
    # 读取原始文件内容
    with open(input_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 删除所有注释行
    content = re.sub(r'//.*', '', content)
    
    # 尝试解析JSON
    try:
        # 首先尝试直接解析
        data = json.loads(content)
        print("JSON格式有效，正在进行规范化...")
    except json.JSONDecodeError as e:
        print(f"JSON解析错误: {str(e)}")
        print("尝试修复常见错误...")
        
        # 修复特定错误：中文引号问题
        content = content.replace('"闭月羞花"之貌', '"闭月羞花"之貌')
        
        # 修复特定错误：缺少逗号
        content = content.replace(
            '"briefDescription": "中国古代四大美女之一，被王允用于离间董卓与吕布的连环计中，"闭月羞花"之貌"', 
            '"briefDescription": "中国古代四大美女之一，被王允用于离间董卓与吕布的连环计中，闭月羞花之貌"'
        )
        
        # 再次尝试解析
        try:
            data = json.loads(content)
            print("修复成功，JSON现在有效")
        except json.JSONDecodeError as e:
            print(f"修复失败，仍存在错误: {str(e)}")
            return False
    
    # 写入规范化的JSON
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    
    print(f"已保存清理后的JSON到: {output_path}")
    print(f"共包含 {len(data['characters'])} 个角色")
    return True

if __name__ == "__main__":
    input_file = './虫遇/Resources/characters.json'
    output_file = './虫遇/Resources/characters_clean.json'
    
    if clean_json_file(input_file, output_file):
        print("处理完成")
    else:
        print("处理失败") 