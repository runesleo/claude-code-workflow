# 贪吃蛇游戏实现计划

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 创建一个单文件HTML5 Canvas贪吃蛇游戏，包含计分、速度递增、暂停和移动端支持

**架构：** 单HTML文件实现，使用Canvas API渲染，requestAnimationFrame游戏循环，localStorage存储最高分

**Tech Stack:** HTML5, Canvas API, JavaScript (ES6+)

---

## Task 1: 创建基础HTML结构和Canvas

**Files:**
- Create: `snake-game.html`

**Step 1: 编写HTML基础结构**

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>贪吃蛇游戏</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
            background: #1a1a2e;
            font-family: Arial, sans-serif;
            color: white;
            overflow: hidden;
        }
        
        #gameContainer {
            text-align: center;
        }
        
        #scoreBoard {
            display: flex;
            justify-content: space-between;
            width: 400px;
            margin-bottom: 10px;
            font-size: 18px;
        }
        
        #gameCanvas {
            border: 2px solid #4a4a6a;
            background: #0f0f1e;
        }
        
        #controls {
            margin-top: 15px;
            font-size: 14px;
            color: #888;
        }
        
        #gameOver {
            display: none;
            position: absolute;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            background: rgba(0,0,0,0.9);
            padding: 30px;
            border-radius: 10px;
            text-align: center;
        }
        
        button {
            margin-top: 15px;
            padding: 10px 20px;
            font-size: 16px;
            background: #4CAF50;
            color: white;
            border: none;
            border-radius: 5px;
            cursor: pointer;
        }
        
        button:hover {
            background: #45a049;
        }
        
        @media (max-width: 450px) {
            #gameCanvas {
                width: 90vw;
                height: 90vw;
            }
            #scoreBoard {
                width: 90vw;
            }
        }
    </style>
</head>
<body>
    <div id="gameContainer">
        <div id="scoreBoard">
            <span>分数: <span id="score">0</span></span>
            <span>最高分: <span id="highScore">0</span></span>
        </div>
        <canvas id="gameCanvas" width="400" height="400"></canvas>
        <div id="controls">
            使用方向键或WASD控制 | 空格键暂停
        </div>
    </div>
    
    <div id="gameOver">
        <h2>游戏结束!</h2>
        <p>最终得分: <span id="finalScore">0</span></p>
        <button onclick="restartGame()">重新开始</button>
    </div>

    <script>
        // Game code will go here
    </script>
</body>
</html>
```

**Step 2: 验证HTML结构**

打开文件检查：
- Canvas居中显示
- 分数板在上方
- 控制提示在下方
- 游戏结束弹窗隐藏

**Step 3: Commit**

```bash
git add snake-game.html
git commit -m "feat: add basic HTML structure and canvas"
```

---

## Task 2: 实现游戏核心逻辑

**Files:**
- Modify: `snake-game.html` (在script标签内)

**Step 1: 添加游戏配置和状态变量**

```javascript
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

// 游戏配置
const GRID_SIZE = 20;
const TILE_COUNT = 20;
const BASE_SPEED = 150; // 毫秒

// 游戏状态
let snake = [];
let food = {};
let direction = 'RIGHT';
let nextDirection = 'RIGHT';
let score = 0;
let highScore = localStorage.getItem('snakeHighScore') || 0;
let gameLoop = null;
let lastTime = 0;
let isPaused = false;
let isGameOver = false;
let speed = BASE_SPEED;

// 初始化
function init() {
    document.getElementById('highScore').textContent = highScore;
    resetGame();
    requestAnimationFrame(gameLoop);
}

function resetGame() {
    snake = [
        {x: 10, y: 10},
        {x: 9, y: 10},
        {x: 8, y: 10}
    ];
    direction = 'RIGHT';
    nextDirection = 'RIGHT';
    score = 0;
    speed = BASE_SPEED;
    isPaused = false;
    isGameOver = false;
    document.getElementById('score').textContent = score;
    document.getElementById('gameOver').style.display = 'none';
    spawnFood();
}
```

**Step 2: 添加游戏循环**

```javascript
function gameLoop(currentTime) {
    if (isGameOver) return;
    
    const deltaTime = currentTime - lastTime;
    
    if (deltaTime >= speed && !isPaused) {
        update();
        lastTime = currentTime;
    }
    
    draw();
    requestAnimationFrame(gameLoop);
}
```

**Step 3: Commit**

```bash
git add snake-game.html
git commit -m "feat: add game configuration and main loop"
```

---

## Task 3: 实现蛇的移动和食物生成

**Files:**
- Modify: `snake-game.html`

**Step 1: 实现蛇的移动逻辑**

```javascript
function update() {
    direction = nextDirection;
    
    const head = {...snake[0]};
    
    switch(direction) {
        case 'UP': head.y--; break;
        case 'DOWN': head.y++; break;
        case 'LEFT': head.x--; break;
        case 'RIGHT': head.x++; break;
    }
    
    // 检查碰撞
    if (head.x < 0 || head.x >= TILE_COUNT || 
        head.y < 0 || head.y >= TILE_COUNT ||
        snake.some(segment => segment.x === head.x && segment.y === head.y)) {
        gameOver();
        return;
    }
    
    snake.unshift(head);
    
    // 检查是否吃到食物
    if (head.x === food.x && head.y === food.y) {
        score += 10;
        document.getElementById('score').textContent = score;
        
        // 速度递增（每50分加速一次）
        if (score % 50 === 0 && speed > 50) {
            speed -= 10;
        }
        
        spawnFood();
    } else {
        snake.pop();
    }
}
```

**Step 2: 实现食物生成**

```javascript
function spawnFood() {
    do {
        food = {
            x: Math.floor(Math.random() * TILE_COUNT),
            y: Math.floor(Math.random() * TILE_COUNT)
        };
    } while (snake.some(segment => segment.x === food.x && segment.y === food.y));
}
```

**Step 3: Commit**

```bash
git add snake-game.html
git commit -m "feat: implement snake movement and food spawning"
```

---

## Task 4: 实现渲染和键盘控制

**Files:**
- Modify: `snake-game.html`

**Step 1: 实现渲染函数**

```javascript
function draw() {
    // 清空画布
    ctx.fillStyle = '#0f0f1e';
    ctx.fillRect(0, 0, canvas.width, canvas.height);
    
    // 绘制网格（可选，用于视觉效果）
    ctx.strokeStyle = '#1a1a2e';
    ctx.lineWidth = 0.5;
    for (let i = 0; i <= TILE_COUNT; i++) {
        ctx.beginPath();
        ctx.moveTo(i * GRID_SIZE, 0);
        ctx.lineTo(i * GRID_SIZE, canvas.height);
        ctx.stroke();
        ctx.beginPath();
        ctx.moveTo(0, i * GRID_SIZE);
        ctx.lineTo(canvas.width, i * GRID_SIZE);
        ctx.stroke();
    }
    
    // 绘制食物
    ctx.fillStyle = '#ff6b6b';
    ctx.beginPath();
    ctx.arc(
        food.x * GRID_SIZE + GRID_SIZE/2,
        food.y * GRID_SIZE + GRID_SIZE/2,
        GRID_SIZE/2 - 2,
        0,
        Math.PI * 2
    );
    ctx.fill();
    
    // 绘制蛇
    snake.forEach((segment, index) => {
        if (index === 0) {
            ctx.fillStyle = '#4CAF50'; // 蛇头
        } else {
            ctx.fillStyle = '#81C784'; // 蛇身
        }
        ctx.fillRect(
            segment.x * GRID_SIZE + 1,
            segment.y * GRID_SIZE + 1,
            GRID_SIZE - 2,
            GRID_SIZE - 2
        );
    });
    
    // 绘制暂停提示
    if (isPaused) {
        ctx.fillStyle = 'rgba(0, 0, 0, 0.7)';
        ctx.fillRect(0, 0, canvas.width, canvas.height);
        ctx.fillStyle = 'white';
        ctx.font = '30px Arial';
        ctx.textAlign = 'center';
        ctx.fillText('暂停', canvas.width/2, canvas.height/2);
    }
}
```

**Step 2: 实现键盘控制**

```javascript
document.addEventListener('keydown', (e) => {
    if (isGameOver) return;
    
    switch(e.key) {
        case 'ArrowUp':
        case 'w':
        case 'W':
            if (direction !== 'DOWN') nextDirection = 'UP';
            break;
        case 'ArrowDown':
        case 's':
        case 'S':
            if (direction !== 'UP') nextDirection = 'DOWN';
            break;
        case 'ArrowLeft':
        case 'a':
        case 'A':
            if (direction !== 'RIGHT') nextDirection = 'LEFT';
            break;
        case 'ArrowRight':
        case 'd':
        case 'D':
            if (direction !== 'LEFT') nextDirection = 'RIGHT';
            break;
        case ' ':
            e.preventDefault();
            isPaused = !isPaused;
            break;
    }
});
```

**Step 3: 实现游戏结束和重新开始**

```javascript
function gameOver() {
    isGameOver = true;
    
    if (score > highScore) {
        highScore = score;
        localStorage.setItem('snakeHighScore', highScore);
        document.getElementById('highScore').textContent = highScore;
    }
    
    document.getElementById('finalScore').textContent = score;
    document.getElementById('gameOver').style.display = 'block';
}

function restartGame() {
    resetGame();
    lastTime = performance.now();
    requestAnimationFrame(gameLoop);
}
```

**Step 4: Commit**

```bash
git add snake-game.html
git commit -m "feat: add rendering, keyboard controls, and game over logic"
```

---

## Task 5: 实现移动端触摸控制

**Files:**
- Modify: `snake-game.html`

**Step 1: 添加触摸事件处理**

```javascript
let touchStartX = 0;
let touchStartY = 0;

canvas.addEventListener('touchstart', (e) => {
    e.preventDefault();
    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
}, {passive: false});

canvas.addEventListener('touchmove', (e) => {
    e.preventDefault();
}, {passive: false});

canvas.addEventListener('touchend', (e) => {
    e.preventDefault();
    
    if (isGameOver || isPaused) return;
    
    const touchEndX = e.changedTouches[0].clientX;
    const touchEndY = e.changedTouches[0].clientY;
    
    const dx = touchEndX - touchStartX;
    const dy = touchEndY - touchStartY;
    
    const minSwipeDistance = 30;
    
    if (Math.abs(dx) > Math.abs(dy)) {
        // 水平滑动
        if (Math.abs(dx) > minSwipeDistance) {
            if (dx > 0 && direction !== 'LEFT') {
                nextDirection = 'RIGHT';
            } else if (dx < 0 && direction !== 'RIGHT') {
                nextDirection = 'LEFT';
            }
        }
    } else {
        // 垂直滑动
        if (Math.abs(dy) > minSwipeDistance) {
            if (dy > 0 && direction !== 'UP') {
                nextDirection = 'DOWN';
            } else if (dy < 0 && direction !== 'DOWN') {
                nextDirection = 'UP';
            }
        }
    }
}, {passive: false});
```

**Step 2: 更新控制提示**

修改HTML中的controls div：
```html
<div id="controls">
    <span id="desktopControls">使用方向键或WASD控制 | 空格键暂停</span>
    <span id="mobileControls" style="display:none;">滑动屏幕控制方向</span>
</div>
```

**Step 3: 添加设备检测**

在script末尾添加：
```javascript
// 检测设备类型
if ('ontouchstart' in window || navigator.maxTouchPoints > 0) {
    document.getElementById('desktopControls').style.display = 'none';
    document.getElementById('mobileControls').style.display = 'inline';
}

// 启动游戏
init();
```

**Step 4: Commit**

```bash
git add snake-game.html
git commit -m "feat: add mobile touch controls"
```

---

## Task 6: 测试和验证

**Files:**
- Test: `snake-game.html`

**Step 1: 功能测试清单**

- [ ] 游戏正常启动，蛇向右移动
- [ ] 方向键控制蛇转向
- [ ] WASD键控制蛇转向
- [ ] 吃到食物后蛇增长
- [ ] 分数正确增加
- [ ] 速度随分数递增
- [ ] 撞墙游戏结束
- [ ] 撞自己游戏结束
- [ ] 空格键暂停/继续
- [ ] 游戏结束显示正确分数
- [ ] 最高分保存到localStorage
- [ ] 重新开始按钮正常工作
- [ ] 移动端滑动控制正常

**Step 2: 浏览器测试**

在不同浏览器中测试：
```bash
# 启动本地服务器
python3 -m http.server 8000
# 或
npx serve .
```

访问 http://localhost:8000/snake-game.html

**Step 3: Commit**

```bash
git add snake-game.html
git commit -m "test: verify all game features work correctly"
```

---

## 最终交付

游戏文件：`snake-game.html`

运行方式：
1. 双击文件在浏览器中打开
2. 或使用本地服务器访问

功能完整清单：
- ✅ 基础移动和吃食物
- ✅ 计分系统（当前分+最高分）
- ✅ 速度递增（每50分加速）
- ✅ 暂停/继续功能
- ✅ 移动端触摸控制
- ✅ 游戏结束和重新开始
