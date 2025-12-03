#!/bin/bash
# 虫遇后端配置验证脚本
# 用于快速检查服务器状态和配置是否正确

echo "🔍 虫遇后端配置验证工具"
echo "=================================="
echo ""

# 1. 检查进程状态
echo "1️⃣  进程状态检查"
PROCESS=$(ps aux | grep "node.*server.js" | grep -v grep)
if [ -n "$PROCESS" ]; then
    PID=$(echo "$PROCESS" | awk '{print $2}')
    echo "✅ 服务器运行中"
    echo "   PID: $PID"
    echo "   进程: $(echo "$PROCESS" | awk '{print $11, $12, $13}')"
else
    echo "❌ 服务器未运行"
    exit 1
fi
echo ""

# 2. 检查端口监听
echo "2️⃣  端口监听检查"
PORT_CHECK=$(lsof -i :3000 2>/dev/null)
if [ -n "$PORT_CHECK" ]; then
    echo "✅ 端口3000正常监听"
    echo "$PORT_CHECK" | head -2
else
    PORT_CHECK=$(lsof -i :8787 2>/dev/null)
    if [ -n "$PORT_CHECK" ]; then
        echo "✅ 端口8787正常监听"
        echo "$PORT_CHECK" | head -2
    else
        echo "❌ 端口未监听"
    fi
fi
echo ""

# 3. 检查配置文件
echo "3️⃣  配置文件检查"
if [ -f "production.env" ]; then
    CREDITS=$(grep "^CREDITS_PER_1K_TOKENS=" production.env | cut -d'=' -f2)
    MODEL=$(grep "^PROVIDER_MODEL=" production.env | cut -d'=' -f2)
    echo "✅ production.env 存在"
    echo "   CREDITS_PER_1K_TOKENS = $CREDITS"
    echo "   PROVIDER_MODEL = $MODEL"
    
    # 验证费率是否合理
    if [ "$CREDITS" = "13" ]; then
        echo "   ✅ 费率设置正确（13币/1K tokens）"
    elif [ "$CREDITS" = "100" ]; then
        echo "   ⚠️  费率为旧值（100币/1K tokens），建议改为13"
    else
        echo "   ⚠️  费率为自定义值：$CREDITS"
    fi
else
    echo "❌ production.env 不存在"
fi
echo ""

# 4. 检查运行时配置
echo "4️⃣  运行时配置检查"
if [ -f "server.log" ]; then
    echo "✅ server.log 存在"
    
    # 提取最新的配置日志
    RUNTIME_CREDITS=$(grep "CREDITS_PER_1K_TOKENS" server.log | tail -1 | sed 's/.*= //')
    RUNTIME_MODEL=$(grep "\[Config\] PROVIDER_MODEL" server.log | tail -1 | sed 's/.*= //')
    RUNTIME_ENV=$(grep "NODE_ENV" server.log | tail -1 | sed 's/.*= //')
    
    if [ -n "$RUNTIME_CREDITS" ]; then
        echo "   CREDITS_PER_1K_TOKENS = $RUNTIME_CREDITS"
        
        # 验证是否和配置文件一致
        if [ "$RUNTIME_CREDITS" = "13" ]; then
            echo "   ✅ 运行时费率正确（13币/1K tokens）"
        elif [ "$RUNTIME_CREDITS" = "100" ]; then
            echo "   ❌ 运行时费率为旧值（100币/1K tokens）"
            echo "   👉 需要重启服务器: ./restart-production.sh"
        else
            echo "   ⚠️  运行时费率为: $RUNTIME_CREDITS"
        fi
    else
        echo "   ❌ 未找到运行时配置（可能是旧版本）"
    fi
    
    if [ -n "$RUNTIME_MODEL" ]; then
        echo "   PROVIDER_MODEL = $RUNTIME_MODEL"
    fi
    
    if [ -n "$RUNTIME_ENV" ]; then
        echo "   NODE_ENV = $RUNTIME_ENV"
    fi
else
    echo "❌ server.log 不存在"
fi
echo ""

# 5. 检查最新错误
echo "5️⃣  错误日志检查"
if [ -f "server.log" ]; then
    ERROR_COUNT=$(grep -i error server.log | wc -l | xargs)
    RECENT_ERRORS=$(grep -i error server.log | tail -3)
    
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "⚠️  发现 $ERROR_COUNT 个错误日志"
        if [ -n "$RECENT_ERRORS" ]; then
            echo "   最近的错误:"
            echo "$RECENT_ERRORS" | sed 's/^/   /'
        fi
    else
        echo "✅ 无错误日志"
    fi
else
    echo "⏭️  跳过（无日志文件）"
fi
echo ""

# 6. 计算费率对比
echo "6️⃣  费率对比分析"
if [ -n "$RUNTIME_CREDITS" ]; then
    echo "   场景: 生成1篇帖子（2000 tokens）"
    
    # 计算新费率消耗
    NEW_COST=$(echo "scale=1; 2000 / 1000 * $RUNTIME_CREDITS" | bc)
    echo "   当前消耗: ${NEW_COST}虫洞币"
    
    # 计算旧费率消耗
    OLD_COST=$(echo "scale=1; 2000 / 1000 * 100" | bc)
    echo "   旧版消耗: ${OLD_COST}虫洞币"
    
    # 计算节省比例
    SAVING=$(echo "scale=1; 100 - ($NEW_COST / $OLD_COST * 100)" | bc)
    echo "   节省: ${SAVING}%"
    
    # 计算6元档可生成数
    GENERATIONS=$(echo "scale=1; 648 / $NEW_COST" | bc)
    echo ""
    echo "   6元档(648币)可生成:"
    echo "   - 当前: 约${GENERATIONS}篇"
    echo "   - 旧版: 约3.2篇"
fi
echo ""

# 7. 健康度评分
echo "7️⃣  系统健康度"
SCORE=0

# 进程运行 +20分
if [ -n "$PROCESS" ]; then
    SCORE=$((SCORE + 20))
fi

# 端口监听 +20分
if [ -n "$PORT_CHECK" ]; then
    SCORE=$((SCORE + 20))
fi

# 配置文件正确 +20分
if [ "$CREDITS" = "13" ]; then
    SCORE=$((SCORE + 20))
fi

# 运行时配置正确 +30分
if [ "$RUNTIME_CREDITS" = "13" ]; then
    SCORE=$((SCORE + 30))
fi

# 无错误日志 +10分
if [ "$ERROR_COUNT" = "0" ] || [ -z "$ERROR_COUNT" ]; then
    SCORE=$((SCORE + 10))
fi

echo "   总分: $SCORE/100"
if [ $SCORE -ge 90 ]; then
    echo "   ✅ 优秀 - 系统运行正常"
elif [ $SCORE -ge 70 ]; then
    echo "   ⚠️  良好 - 建议检查配置"
elif [ $SCORE -ge 50 ]; then
    echo "   ⚠️  一般 - 需要重启服务器"
else
    echo "   ❌ 差 - 系统存在问题，需要处理"
fi
echo ""

# 8. 快捷操作提示
echo "=================================="
echo "📚 快捷命令:"
echo "   查看日志: tail -f server.log"
echo "   重启服务: ./restart-production.sh"
echo "   停止服务: pkill -f 'node.*server.js'"
echo "   查看进程: ps aux | grep node | grep -v grep"
echo ""
