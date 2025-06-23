import json
import re

try:
    # 读取原始JSON文件
    with open('./虫遇/Resources/characters.json', 'r') as f:
        content = f.read()
    
    # 删除JSON中的注释
    content = re.sub(r'//.*', '', content)
    
    # 手动修复第1523行附近的格式问题
    # 查找并替换JSON格式错误位置的内容
    content = content.replace('"briefDescription": "古罗马共和国末期的军事政治家，征服高卢，成为罗马的终身独裁官，为罗马帝国奠基"', 
                             '"briefDescription": "古罗马共和国末期的军事政治家，征服高卢，成为罗马的终身独裁官，为罗马帝国奠基",')
    
    # 尝试解析修复后的JSON
    parsed = json.loads(content)
    
    # 写入修复后的JSON
    with open('./虫遇/Resources/characters_fixed.json', 'w') as f:
        json.dump(parsed, f, ensure_ascii=False, indent=2)
    
    print('JSON已修复并保存到characters_fixed.json')
except Exception as e:
    print(f'错误: {str(e)}')
