#!/bin/bash
echo "�� 开始部署虫遇APP后端服务器..."

# 更新系统
yum update -y
yum install -y wget curl git

# 安装Node.js 18
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs

# 安装MySQL
yum install -y mysql-server
systemctl start mysqld
systemctl enable mysqld

# 设置MySQL root密码
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'ChongYu2024!';"
mysql -u root -pChongYu2024! -e "CREATE DATABASE chongyu_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 创建项目目录
mkdir -p /var/www/chongyu
cd /var/www/chongyu

# 创建package.json
cat > package.json << 'PACKAGE_EOF'
{
  "name": "chongyu-backend",
  "version": "1.0.0",
  "description": "虫遇APP后端服务",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "nodemon server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "mysql2": "^3.6.0",
    "cors": "^2.8.5",
    "bcryptjs": "^2.4.3",
    "jsonwebtoken": "^9.0.2",
    "multer": "^1.4.5-lts.1",
    "helmet": "^7.0.0",
    "express-rate-limit": "^6.10.0",
    "dotenv": "^16.3.1"
  }
}
PACKAGE_EOF

# 安装依赖
npm install

# 创建主服务器文件
cat > server.js << 'SERVER_EOF'
const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');

const app = express();
const PORT = 3000;

// 安全中间件
app.use(helmet());
app.use(cors());
app.use(express.json());

// 限流
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15分钟
  max: 100 // 限制每个IP 15分钟内最多100个请求
});
app.use(limiter);

// 数据库连接
const db = mysql.createConnection({
  host: 'localhost',
  user: 'root',
  password: 'ChongYu2024!',
  database: 'chongyu_db'
});

// 连接数据库
db.connect((err) => {
  if (err) {
    console.error('数据库连接失败:', err);
    return;
  }
  console.log('✅ 数据库连接成功');
});

// 创建用户表
db.execute(`
  CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(255),
    bio TEXT,
    location VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  )
`);

// 创建昆虫发现表
db.execute(`
  CREATE TABLE IF NOT EXISTS discoveries (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    image_url VARCHAR(255),
    location VARCHAR(100),
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    insect_type VARCHAR(100),
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    likes_count INT DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
  )
`);

// 创建点赞表
db.execute(`
  CREATE TABLE IF NOT EXISTS likes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    discovery_id INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY unique_like (user_id, discovery_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (discovery_id) REFERENCES discoveries(id) ON DELETE CASCADE
  )
`);

// JWT密钥
const JWT_SECRET = 'chongyu_jwt_secret_2024';

// 中间件：验证JWT token
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: '需要登录' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ error: '无效的token' });
    }
    req.user = user;
    next();
  });
};

// 基础路由
app.get('/', (req, res) => {
  res.json({
    message: '🐛 虫遇APP后端服务正在运行',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString()
  });
});

// 用户注册
app.post('/api/register', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    if (!username || !email || !password) {
      return res.status(400).json({ error: '用户名、邮箱和密码都是必填的' });
    }

    // 检查用户是否已存在
    db.execute('SELECT id FROM users WHERE username = ? OR email = ?', [username, email], async (err, results) => {
      if (err) {
        return res.status(500).json({ error: '数据库错误' });
      }

      if (results.length > 0) {
        return res.status(400).json({ error: '用户名或邮箱已存在' });
      }

      // 加密密码
      const passwordHash = await bcrypt.hash(password, 10);

      // 创建用户
      db.execute(
        'INSERT INTO users (username, email, password_hash) VALUES (?, ?, ?)',
        [username, email, passwordHash],
        (err, results) => {
          if (err) {
            return res.status(500).json({ error: '创建用户失败' });
          }

          const token = jwt.sign(
            { id: results.insertId, username: username },
            JWT_SECRET,
            { expiresIn: '7d' }
          );

          res.status(201).json({
            message: '注册成功',
            token: token,
            user: {
              id: results.insertId,
              username: username,
              email: email
            }
          });
        }
      );
    });
  } catch (error) {
    res.status(500).json({ error: '服务器错误' });
  }
});

// 用户登录
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;

  if (!username || !password) {
    return res.status(400).json({ error: '用户名和密码都是必填的' });
  }

  db.execute('SELECT * FROM users WHERE username = ?', [username], async (err, results) => {
    if (err) {
      return res.status(500).json({ error: '数据库错误' });
    }

    if (results.length === 0) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    const user = results[0];
    const isValidPassword = await bcrypt.compare(password, user.password_hash);

    if (!isValidPassword) {
      return res.status(401).json({ error: '用户名或密码错误' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    res.json({
      message: '登录成功',
      token: token,
      user: {
        id: user.id,
        username: user.username,
        email: user.email,
        avatar_url: user.avatar_url,
        bio: user.bio,
        location: user.location
      }
    });
  });
});

// 获取用户信息
app.get('/api/user/profile', authenticateToken, (req, res) => {
  db.execute('SELECT id, username, email, avatar_url, bio, location, created_at FROM users WHERE id = ?', 
    [req.user.id], (err, results) => {
    if (err) {
      return res.status(500).json({ error: '数据库错误' });
    }

    if (results.length === 0) {
      return res.status(404).json({ error: '用户不存在' });
    }

    res.json({ user: results[0] });
  });
});

// 发布昆虫发现
app.post('/api/discoveries', authenticateToken, (req, res) => {
  const { title, description, image_url, location, latitude, longitude, insect_type } = req.body;

  if (!title) {
    return res.status(400).json({ error: '标题是必填的' });
  }

  db.execute(
    'INSERT INTO discoveries (user_id, title, description, image_url, location, latitude, longitude, insect_type) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [req.user.id, title, description, image_url, location, latitude, longitude, insect_type],
    (err, results) => {
      if (err) {
        return res.status(500).json({ error: '发布失败' });
      }

      res.status(201).json({
        message: '发布成功',
        discovery: {
          id: results.insertId,
          title,
          description,
          image_url,
          location,
          latitude,
          longitude,
          insect_type
        }
      });
    }
  );
});

// 获取昆虫发现列表
app.get('/api/discoveries', (req, res) => {
  const page = parseInt(req.query.page) || 1;
  const limit = parseInt(req.query.limit) || 10;
  const offset = (page - 1) * limit;

  db.execute(`
    SELECT d.*, u.username, u.avatar_url 
    FROM discoveries d 
    JOIN users u ON d.user_id = u.id 
    ORDER BY d.discovered_at DESC 
    LIMIT ? OFFSET ?
  `, [limit, offset], (err, results) => {
    if (err) {
      return res.status(500).json({ error: '获取数据失败' });
    }

    res.json({
      discoveries: results,
      page: page,
      limit: limit,
      total: results.length
    });
  });
});

// 点赞/取消点赞
app.post('/api/discoveries/:id/like', authenticateToken, (req, res) => {
  const discoveryId = req.params.id;
  const userId = req.user.id;

  // 检查是否已经点赞
  db.execute('SELECT id FROM likes WHERE user_id = ? AND discovery_id = ?', 
    [userId, discoveryId], (err, results) => {
    if (err) {
      return res.status(500).json({ error: '数据库错误' });
    }

    if (results.length > 0) {
      // 取消点赞
      db.execute('DELETE FROM likes WHERE user_id = ? AND discovery_id = ?', 
        [userId, discoveryId], (err) => {
        if (err) {
          return res.status(500).json({ error: '取消点赞失败' });
        }

        // 更新点赞数
        db.execute('UPDATE discoveries SET likes_count = likes_count - 1 WHERE id = ?', 
          [discoveryId], (err) => {
          if (err) {
            return res.status(500).json({ error: '更新点赞数失败' });
          }
          res.json({ message: '取消点赞成功', liked: false });
        });
      });
    } else {
      // 添加点赞
      db.execute('INSERT INTO likes (user_id, discovery_id) VALUES (?, ?)', 
        [userId, discoveryId], (err) => {
        if (err) {
          return res.status(500).json({ error: '点赞失败' });
        }

        // 更新点赞数
        db.execute('UPDATE discoveries SET likes_count = likes_count + 1 WHERE id = ?', 
          [discoveryId], (err) => {
          if (err) {
            return res.status(500).json({ error: '更新点赞数失败' });
          }
          res.json({ message: '点赞成功', liked: true });
        });
      });
    }
  });
});

// 健康检查
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// 启动服务器
app.listen(PORT, '0.0.0.0', () => {
  console.log(`🚀 虫遇APP后端服务已启动`);
  console.log(`📡 服务地址: http://0.0.0.0:${PORT}`);
  console.log(`🌍 公网访问: http://121.40.184.29:${PORT}`);
  console.log(`📊 健康检查: http://121.40.184.29:${PORT}/health`);
});

// 优雅关闭
process.on('SIGTERM', () => {
  console.log('收到SIGTERM信号，正在关闭服务器...');
  db.end();
  process.exit(0);
});

process.on('SIGINT', () => {
  console.log('收到SIGINT信号，正在关闭服务器...');
  db.end();
  process.exit(0);
});
SERVER_EOF

# 安装PM2进程管理器
npm install -g pm2

# 创建PM2配置文件
cat > ecosystem.config.js << 'PM2_EOF'
module.exports = {
  apps: [{
    name: 'chongyu-backend',
    script: 'server.js',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '1G',
    env: {
      NODE_ENV: 'production',
      PORT: 3000
    }
  }]
};
PM2_EOF

# 启动服务
pm2 start ecosystem.config.js
pm2 save
pm2 startup

# 配置防火墙
firewall-cmd --permanent --add-port=3000/tcp
firewall-cmd --reload

echo "✅ 部署完成！"
echo "🌍 API地址: http://121.40.184.29:3000"
echo "📊 健康检查: http://121.40.184.29:3000/health"
echo "🔧 管理命令:"
echo "  - 查看日志: pm2 logs chongyu-backend"
echo "  - 重启服务: pm2 restart chongyu-backend"
echo "  - 停止服务: pm2 stop chongyu-backend"
