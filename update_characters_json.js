#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

// 读取characters.json文件
const charactersPath = path.join('虫遇', 'Resources', 'characters.json');
const charactersData = JSON.parse(fs.readFileSync(charactersPath, 'utf8'));

// 需要添加的角色
const missingCharacters = [
  {
    "id": "aristotle",
    "name": "亚里士多德",
    "type": "historical",
    "subtype": "philosopher",
    "era": "古希腊",
    "primaryField": "哲学家",
    "briefDescription": "古希腊哲学家、科学家，柏拉图的学生，亚历山大大帝的老师",
    "avatarName": "aristotle",
    "region": "希腊",
    "contentAffinities": {
      "古潮新语": 0.9,
      "穿越吐槽": 0.7,
      "日常心情": 0.6,
      "虫洞共鸣": 0.8,
      "时空记事": 0.85
    }
  },
  {
    "id": "curie",
    "name": "居里夫人",
    "type": "historical",
    "subtype": "scientist",
    "era": "近代",
    "primaryField": "物理学家、化学家",
    "briefDescription": "放射性研究先驱，首位获得两次诺贝尔奖的科学家",
    "avatarName": "curie",
    "region": "波兰/法国",
    "contentAffinities": {
      "古潮新语": 0.7,
      "穿越吐槽": 0.8,
      "日常心情": 0.6,
      "虫洞共鸣": 0.9,
      "时空记事": 0.75
    }
  },
  {
    "id": "hawking",
    "name": "霍金",
    "type": "historical",
    "subtype": "scientist",
    "era": "现代",
    "primaryField": "物理学家",
    "briefDescription": "理论物理学家，黑洞辐射理论提出者，《时间简史》作者",
    "avatarName": "hawking",
    "region": "英国",
    "contentAffinities": {
      "古潮新语": 0.8,
      "穿越吐槽": 0.9,
      "日常心情": 0.7,
      "虫洞共鸣": 0.95,
      "时空记事": 0.85
    }
  },
  {
    "id": "libai",
    "name": "李白",
    "type": "historical",
    "subtype": "poet",
    "era": "唐代",
    "primaryField": "诗人",
    "briefDescription": "唐代伟大的浪漫主义诗人，被称为"诗仙"",
    "avatarName": "libai",
    "region": "中国",
    "contentAffinities": {
      "古潮新语": 0.95,
      "穿越吐槽": 0.8,
      "日常心情": 0.9,
      "虫洞共鸣": 0.7,
      "时空记事": 0.85
    }
  },
  {
    "id": "mozart",
    "name": "莫扎特",
    "type": "historical",
    "subtype": "musician",
    "era": "古典时期",
    "primaryField": "作曲家",
    "briefDescription": "古典主义音乐代表人物，音乐神童",
    "avatarName": "mozart",
    "region": "奥地利",
    "contentAffinities": {
      "古潮新语": 0.8,
      "穿越吐槽": 0.7,
      "日常心情": 0.9,
      "虫洞共鸣": 0.75,
      "时空记事": 0.8
    }
  },
  {
    "id": "newton",
    "name": "牛顿",
    "type": "historical",
    "subtype": "scientist",
    "era": "近代",
    "primaryField": "物理学家、数学家",
    "briefDescription": "经典力学奠基人，发现万有引力定律",
    "avatarName": "newton",
    "region": "英国",
    "contentAffinities": {
      "古潮新语": 0.85,
      "穿越吐槽": 0.8,
      "日常心情": 0.6,
      "虫洞共鸣": 0.9,
      "时空记事": 0.85
    }
  },
  {
    "id": "spike",
    "name": "斯派克",
    "type": "fictional",
    "subtype": "anime",
    "era": "未来",
    "primaryField": "赏金猎人",
    "briefDescription": "《星际牛仔》主角，前辛迪加成员",
    "avatarName": "spike",
    "region": "火星",
    "contentAffinities": {
      "古潮新语": 0.7,
      "穿越吐槽": 0.9,
      "日常心情": 0.8,
      "虫洞共鸣": 0.75,
      "时空记事": 0.7
    }
  }
];

// 添加缺失的角色
missingCharacters.forEach(character => {
  // 检查角色是否已存在
  const exists = charactersData.characters.some(c => c.id === character.id);
  if (!exists) {
    charactersData.characters.push(character);
    console.log(`✅ 已添加角色: ${character.name} (${character.id})`);
  } else {
    console.log(`⚠️ 角色已存在: ${character.name} (${character.id})`);
  }
});

// 保存更新后的文件
fs.writeFileSync(charactersPath, JSON.stringify(charactersData, null, 2), 'utf8');
console.log(`✅ 已更新characters.json文件，现有角色数量: ${charactersData.characters.length}`); 