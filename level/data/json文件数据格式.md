---
title: json文件数据格式
language_tabs:
  - gdscript: GDScript
toc_footers: []
includes: []
search: true
code_clipboard: true
highlight_theme: darkula
headingLevel: 2
generator: "@tarslib/widdershins v4.0.30"
---
# json文件数据格式

Base URLs:

# Authentication

# 数据模型

<h2 id="tocS_ButtonController">ButtonController</h2>

<a id="schemabuttoncontroller"></a>
<a id="schema_ButtonController"></a>
<a id="tocSbuttoncontroller"></a>
<a id="tocsbuttoncontroller"></a>

```json
{
  "X": 0,
  "Y": 0,
  "Class": "ButtonController",
  "name": "string",
  "button": [
    {
      "X": 0,
      "Y": 0,
      "Class": "FakableButton",
      "name": "string",
      "fake": true,
      "fakable": true,
      "color": "blue",
      "tooltip_offset": [
        null,
        null
      ]
    }
  ],
  "wall": [
    {
      "X": 0,
      "Y": 0,
      "Class": "FakableWall",
      "name": "string",
      "fake": true,
      "fakable": true,
      "color": "blue",
      "facing": "N",
      "size": [
        null,
        null
      ],
      "auto_offset": true
    }
  ],
  "size_on": [
    0,
    0
  ],
  "size_off": [
    0,
    0
  ]
}
```

### 属性

| 名称   | 类型    | 必选  | 约束 | 中文名 | 说明                         |
| ------ | ------- | ----- | ---- | ------ | ---------------------------- |
| X      | number  | true  | none |        | 世界坐标X（格）              |
| Y      | number  | true  | none |        | 世界坐标Y（格）              |
| Class  | string  | true  | none |        | 物体类型                     |
| name   | string  | false | none |        | 自定义引用键名               |
| button | [anyOf] | false | none |        | 按钮数组<br />字段名可为复数 |

anyOf

| 名称            | 类型                                 | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------------------------------------ | ----- | ---- | ------ | ---- |
| »*anonymous* | [FakableButton](#schemafakablebutton) | false | none |        | none |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | none           |
| »» bind       | string | true  | none |        | 自定义引用键名 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | string | false | none |        | 自定义引用键名 |

continued

| 名称 | 类型    | 必选  | 约束 | 中文名 | 说明                       |
| ---- | ------- | ----- | ---- | ------ | -------------------------- |
| wall | [anyOf] | false | none |        | 墙数组<br />字段名可为复数 |

anyOf

| 名称            | 类型                             | 必选  | 约束 | 中文名 | 说明 |
| --------------- | -------------------------------- | ----- | ---- | ------ | ---- |
| »*anonymous* | [FakableWall](#schemafakablewall) | false | none |        | none |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | none           |
| »» bind       | string | true  | none |        | 自定义引用键名 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | string | false | none |        | 自定义引用键名 |

continued

| 名称    | 类型 | 必选  | 约束 | 中文名 | 说明                 |
| ------- | ---- | ----- | ---- | ------ | -------------------- |
| size_on | any  | false | none |        | 按钮开启时，墙的尺寸 |

anyOf

| 名称            | 类型      | 必选  | 约束 | 中文名 | 说明             |
| --------------- | --------- | ----- | ---- | ------ | ---------------- |
| »*anonymous* | [integer] | false | none |        | [x,y] 单位：像素 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | 单位：像素     |
| »» x          | string | true  | none |        | 水平方向的长度 |
| »» y          | string | true  | none |        | 垂直方向的长度 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | 单位：格       |
| »» W          | string | true  | none |        | 水平方向的长度 |
| »» H          | string | true  | none |        | 垂直方向的长度 |

continued

| 名称     | 类型 | 必选  | 约束 | 中文名 | 说明                 |
| -------- | ---- | ----- | ---- | ------ | -------------------- |
| size_off | any  | false | none |        | 按钮关闭时，墙的尺寸 |

anyOf

| 名称            | 类型      | 必选  | 约束 | 中文名 | 说明             |
| --------------- | --------- | ----- | ---- | ------ | ---------------- |
| »*anonymous* | [integer] | false | none |        | [x,y] 单位：像素 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | 单位：像素     |
| »» x          | string | true  | none |        | 水平方向的长度 |
| »» y          | string | true  | none |        | 垂直方向的长度 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | 单位：格       |
| »» W          | string | true  | none |        | 水平方向的长度 |
| »» H          | string | true  | none |        | 垂直方向的长度 |

<h2 id="tocS_FakableButton">FakableButton</h2>

<a id="schemafakablebutton"></a>
<a id="schema_FakableButton"></a>
<a id="tocSfakablebutton"></a>
<a id="tocsfakablebutton"></a>

```json
{
  "X": 0,
  "Y": 0,
  "Class": "FakableButton",
  "name": "string",
  "fake": true,
  "fakable": true,
  "color": "blue",
  "tooltip_offset": [
    0,
    0
  ]
}
```

### 属性

| 名称           | 类型    | 必选  | 约束 | 中文名 | 说明                   |
| -------------- | ------- | ----- | ---- | ------ | ---------------------- |
| X              | number  | true  | none |        | 世界坐标X（格）        |
| Y              | number  | true  | none |        | 世界坐标Y（格）        |
| Class          | string  | true  | none |        | 物体类型               |
| name           | string  | false | none |        | 自定义引用键名         |
| fake           | boolean | false | none |        | 是否为假               |
| fakable        | boolean | false | none |        | 是否可变假             |
| color          | string  | false | none |        | 颜色变体               |
| tooltip_offset | any     | false | none |        | 提示偏移（单位：像素） |

anyOf

| 名称            | 类型      | 必选  | 约束 | 中文名 | 说明 |
| --------------- | --------- | ----- | ---- | ------ | ---- |
| »*anonymous* | [integer] | false | none |        | none |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------ | ----- | ---- | ------ | ---- |
| »*anonymous* | object | false | none |        | none |
| »» x          | string | true  | none |        | none |
| »» y          | string | true  | none |        | none |

#### 枚举值

| 属性  | 值     |
| ----- | ------ |
| color | blue   |
| color | green  |
| color | red    |
| color | orange |

<h2 id="tocS_FakableWall">FakableWall</h2>

<a id="schemafakablewall"></a>
<a id="schema_FakableWall"></a>
<a id="tocSfakablewall"></a>
<a id="tocsfakablewall"></a>

```json
{
  "X": 0,
  "Y": 0,
  "Class": "FakableWall",
  "name": "string",
  "fake": true,
  "fakable": true,
  "color": "blue",
  "facing": "N",
  "size": [
    0,
    0
  ],
  "auto_offset": true
}
```

### 属性

| 名称    | 类型    | 必选  | 约束 | 中文名 | 说明                           |
| ------- | ------- | ----- | ---- | ------ | ------------------------------ |
| X       | number  | true  | none |        | 世界坐标X（格）                |
| Y       | number  | true  | none |        | 世界坐标Y（格）                |
| Class   | string  | true  | none |        | 物体类型                       |
| name    | string  | false | none |        | 自定义引用键名                 |
| fake    | boolean | false | none |        | 是否为假                       |
| fakable | boolean | false | none |        | 是否可变假                     |
| color   | string  | false | none |        | 颜色变体                       |
| facing  | string  | false | none |        | 伸缩时的朝向<br />会影响anchor |
| size    | any     | true  | none |        | 尺寸                           |

anyOf

| 名称            | 类型      | 必选  | 约束 | 中文名 | 说明             |
| --------------- | --------- | ----- | ---- | ------ | ---------------- |
| »*anonymous* | [integer] | false | none |        | [x,y] 单位：像素 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | 单位：像素     |
| »» x          | string | true  | none |        | 水平方向的长度 |
| »» y          | string | true  | none |        | 垂直方向的长度 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | 单位：格       |
| »» W          | string | true  | none |        | 水平方向的长度 |
| »» H          | string | true  | none |        | 垂直方向的长度 |

continued

| 名称        | 类型    | 必选  | 约束 | 中文名 | 说明                             |
| ----------- | ------- | ----- | ---- | ------ | -------------------------------- |
| auto_offset | boolean | false | none |        | 坐标是否按 facing 反方向偏移半格 |

#### 枚举值

| 属性   | 值     |
| ------ | ------ |
| color  | blue   |
| color  | green  |
| color  | red    |
| color  | orange |
| facing | N      |
| facing | S      |
| facing | W      |
| facing | E      |

<h2 id="tocS_FakableBomb">FakableBomb</h2>

<a id="schemafakablebomb"></a>
<a id="schema_FakableBomb"></a>
<a id="tocSfakablebomb"></a>
<a id="tocsfakablebomb"></a>

```json
{
  "X": 0,
  "Y": 0,
  "Class": "FakableBomb",
  "name": "string",
  "fake": true,
  "fakable": true,
  "color": "blue"
}
```

### 属性

| 名称    | 类型    | 必选  | 约束 | 中文名 | 说明            |
| ------- | ------- | ----- | ---- | ------ | --------------- |
| X       | number  | true  | none |        | 世界坐标X（格） |
| Y       | number  | true  | none |        | 世界坐标Y（格） |
| Class   | string  | true  | none |        | 物体类型        |
| name    | string  | false | none |        | 自定义引用键名  |
| fake    | boolean | false | none |        | 是否为假        |
| fakable | boolean | false | none |        | 是否可变假      |
| color   | string  | false | none |        | 颜色变体        |

#### 枚举值

| 属性  | 值     |
| ----- | ------ |
| color | blue   |
| color | green  |
| color | red    |
| color | orange |

<h2 id="tocS_Clue">Clue</h2>

<a id="schemaclue"></a>
<a id="schema_Clue"></a>
<a id="tocSclue"></a>
<a id="tocsclue"></a>

```json
{
  "X": 0,
  "Y": 0,
  "Class": "Clue",
  "name": "string",
  "fake": true,
  "fakable": true,
  "facing": "N",
  "content": "线索……",
  "duration": 5,
  "id": -1
}
```

### 属性

| 名称     | 类型    | 必选  | 约束 | 中文名 | 说明                                |
| -------- | ------- | ----- | ---- | ------ | ----------------------------------- |
| X        | number  | true  | none |        | 世界坐标X（格）                     |
| Y        | number  | true  | none |        | 世界坐标Y（格）                     |
| Class    | string  | true  | none |        | 物体类型                            |
| name     | string  | false | none |        | 自定义引用键名                      |
| fake     | boolean | false | none |        | 是否为假                            |
| fakable  | boolean | false | none |        | 是否可变假                          |
| facing   | string  | false | none |        | 朝向                                |
| content  | string  | false | none |        | 线索显示内容                        |
| duration | number  | false | none |        | 线索显示时长（秒）                  |
| id       | integer | false | none |        | 线索唯一标识<br />-1=交互不写入存档 |

#### 枚举值

| 属性   | 值 |
| ------ | -- |
| facing | N  |
| facing | S  |
| facing | W  |
| facing | E  |

<h2 id="tocS_MapMirror">MapMirror</h2>

<a id="schemamapmirror"></a>
<a id="schema_MapMirror"></a>
<a id="tocSmapmirror"></a>
<a id="tocsmapmirror"></a>

```json
{
  "X": 0,
  "Y": 0,
  "Class": "MapMirror",
  "name": "string",
  "axis": "X",
  "tomap": [
    {
      "bind": "string"
    }
  ],
  "tooltip_offset": [
    0,
    0
  ]
}
```

### 属性

| 名称  | 类型   | 必选  | 约束 | 中文名 | 说明            |
| ----- | ------ | ----- | ---- | ------ | --------------- |
| X     | number | true  | none |        | 世界坐标X（格） |
| Y     | number | true  | none |        | 世界坐标Y（格） |
| Class | string | true  | none |        | 物体类型        |
| name  | string | false | none |        | 自定义引用键名  |
| axis  | any    | false | none |        | 映射轴          |

anyOf

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------ | ----- | ---- | ------ | ---- |
| »*anonymous* | string | false | none |        | none |

or

| 名称            | 类型    | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------- | ----- | ---- | ------ | ---- |
| »*anonymous* | integer | false | none |        | none |

continued

| 名称  | 类型    | 必选  | 约束 | 中文名 | 说明       |
| ----- | ------- | ----- | ---- | ------ | ---------- |
| tomap | [anyOf] | false | none |        | 可映射节点 |

anyOf

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | object | false | none |        | none           |
| »» bind       | string | true  | none |        | 自定义引用键名 |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明           |
| --------------- | ------ | ----- | ---- | ------ | -------------- |
| »*anonymous* | string | false | none |        | 自定义引用键名 |

continued

| 名称           | 类型 | 必选  | 约束 | 中文名 | 说明                   |
| -------------- | ---- | ----- | ---- | ------ | ---------------------- |
| tooltip_offset | any  | false | none |        | 提示偏移（单位：像素） |

anyOf

| 名称            | 类型      | 必选  | 约束 | 中文名 | 说明 |
| --------------- | --------- | ----- | ---- | ------ | ---- |
| »*anonymous* | [integer] | false | none |        | none |

or

| 名称            | 类型   | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------ | ----- | ---- | ------ | ---- |
| »*anonymous* | object | false | none |        | none |
| »» x          | string | true  | none |        | none |
| »» y          | string | true  | none |        | none |

#### 枚举值

| 属性          | 值 |
| ------------- | -- |
| *anonymous* | X  |
| *anonymous* | Y  |
| *anonymous* | x  |
| *anonymous* | y  |
| *anonymous* | 0  |
| *anonymous* | 1  |

<h2 id="tocS_Player">Player</h2>

<a id="schemaplayer"></a>
<a id="schema_Player"></a>
<a id="tocSplayer"></a>
<a id="tocsplayer"></a>

```json
{
  "X": 0,
  "Y": 0,
  "type": "Player",
  "name": "string",
  "facing": "N",
  "movable": true,
  "interactable": true,
  "view_angle": 45
}
```

玩家

### 属性

| 名称         | 类型    | 必选  | 约束 | 中文名 | 说明           |
| ------------ | ------- | ----- | ---- | ------ | -------------- |
| X            | number  | true  | none |        | 坐标X（格）    |
| Y            | number  | true  | none |        | 坐标Y（格）    |
| type         | string  | true  | none |        | 角色类型       |
| name         | string  | false | none |        | 自定义引用键名 |
| facing       | string  | false | none |        | 朝向           |
| movable      | boolean | false | none |        | 是否可移动     |
| interactable | boolean | false | none |        | 是否可交互     |
| view_angle   | number  | false | none |        | 视野角度（度） |

#### 枚举值

| 属性   | 值 |
| ------ | -- |
| facing | N  |
| facing | S  |
| facing | W  |
| facing | E  |

<h2 id="tocS_DolosBlack">DolosBlack</h2>

<a id="schemadolosblack"></a>
<a id="schema_DolosBlack"></a>
<a id="tocSdolosblack"></a>
<a id="tocsdolosblack"></a>

```json
{
  "X": 0,
  "Y": 0,
  "type": "DolosBlack",
  "name": "string",
  "facing": "N"
}
```

关卡向导
NPC之一

### 属性

| 名称   | 类型   | 必选  | 约束 | 中文名 | 说明           |
| ------ | ------ | ----- | ---- | ------ | -------------- |
| X      | number | true  | none |        | 坐标X（格）    |
| Y      | number | true  | none |        | 坐标Y（格）    |
| type   | string | true  | none |        | 角色类型       |
| name   | string | false | none |        | 自定义引用键名 |
| facing | string | false | none |        | 朝向           |

#### 枚举值

| 属性   | 值          |
| ------ | ----------- |
| type   | DolosBlack  |
| type   | Dolos_Black |
| facing | N           |
| facing | S           |
| facing | W           |
| facing | E           |

<h2 id="tocS_LevelData">LevelData</h2>

<a id="schemaleveldata"></a>
<a id="schema_LevelData"></a>
<a id="tocSleveldata"></a>
<a id="tocsleveldata"></a>

```json
{
  "format_version": 0,
  "meta": {
    "id": "string",
    "name": "string",
    "description": "string"
  },
  "map": {
    "cell_size": {
      "width": 32,
      "height": 32
    },
    "floor": {
      "X": 0,
      "Y": 0,
      "W": 0,
      "H": 0,
      "seed": -1,
      "preset_tile": [
        {
          "X": 0,
          "Y": 0,
          "tile": [
            null
          ],
          "facing": "["
        }
      ],
      "name": "string"
    },
    "external_wall": [
      {
        "X": 0,
        "Y": 0,
        "dirs": {
          "N": true,
          "S": true,
          "W": true,
          "E": true
        }
      }
    ],
    "exit": {
      "X": 0,
      "Y": 0,
      "facing": "N",
      "next_scene": "string",
      "tooltip_offset": [
        0,
        0
      ]
    }
  },
  "item": [
    {
      "X": 0,
      "Y": 0,
      "Class": "ButtonController",
      "name": "string",
      "button": [
        {}
      ],
      "wall": [
        {}
      ],
      "size_on": [
        null,
        null
      ],
      "size_off": [
        null,
        null
      ]
    }
  ],
  "character": [
    {
      "X": 0,
      "Y": 0,
      "type": "Player",
      "name": "string",
      "facing": "N",
      "movable": true,
      "interactable": true,
      "view_angle": 45
    }
  ],
  "event": [
    {}
  ]
}
```

关卡数据

### 属性

| 名称           | 类型 | 必选 | 约束 | 中文名 | 说明     |
| -------------- | ---- | ---- | ---- | ------ | -------- |
| format_version | any  | true | none |        | 格式版本 |

anyOf

| 名称            | 类型    | 必选  | 约束 | 中文名 | 说明         |
| --------------- | ------- | ----- | ---- | ------ | ------------ |
| »*anonymous* | integer | false | none |        | 确切的版本号 |

or

| 名称            | 类型      | 必选  | 约束 | 中文名 | 说明     |
| --------------- | --------- | ----- | ---- | ------ | -------- |
| »*anonymous* | [integer] | false | none |        | 兼容范围 |

continued

| 名称                | 类型         | 必选  | 约束 | 中文名 | 说明                                                                                            |
| ------------------- | ------------ | ----- | ---- | ------ | ----------------------------------------------------------------------------------------------- |
| meta                | object       | true  | none |        | 元数据（id/name/description）                                                                   |
| » id               | string       | true  | none |        | 关卡唯一标识                                                                                    |
| » name             | string       | false | none |        | 关卡名<br />加载数据时缺省则用 id                                                               |
| » description      | string       | false | none |        | 关卡描述                                                                                        |
| map                 | object       | true  | none |        | 地图（cell_size/floor/external_wall/exit）                                                      |
| » cell_size        | object       | true  | none |        | 单元格尺寸（像素）                                                                              |
| »» width          | integer      | true  | none |        | 宽度                                                                                            |
| »» height         | integer      | true  | none |        | 高度                                                                                            |
| » floor            | object       | false | none |        | 地板                                                                                            |
| »» X              | integer      | true  | none |        | 坐标X（格）                                                                                     |
| »» Y              | integer      | true  | none |        | 坐标Y（格）                                                                                     |
| »» W              | integer      | true  | none |        | 水平方向瓦片数量（格）                                                                          |
| »» H              | integer      | true  | none |        | 垂直方向瓦片数量（格）                                                                          |
| »» seed           | integer      | false | none |        | 随机种子<br />-1=每次随机                                                                       |
| »» preset_tile    | [object]     | false | none |        | 预制瓦片<br />字段名可为复数                                                                    |
| »»» X            | integer      | true  | none |        | 坐标X（格）                                                                                     |
| »»» Y            | integer      | true  | none |        | 坐标Y（格）                                                                                     |
| »»» tile         | [integer]    | true  | none |        | Atlas 图集坐标 [x,y]                                                                            |
| »»» facing       | string       | false | none |        | 朝向                                                                                            |
| »» name           | string       | false | none |        | 自定义引用键名<br />floor 专属                                                                  |
| » external_wall    | [object]     | false | none |        | 外墙节点数组<br />字段名可为复数<br />实例化TileMapLayer                                        |
| »» X              | integer      | true  | none |        | 坐标X（格）                                                                                     |
| »» Y              | integer      | true  | none |        | 坐标Y（格）                                                                                     |
| »» dirs           | object       | false | none |        | 允许相连的方向<br />相邻节点双方相对方向均为true则相连<br />无则自动推导值，相邻距离 ≤ 50 格。 |
| »»» N            | boolean      | false | none |        | none                                                                                            |
| »»» S            | boolean      | false | none |        | none                                                                                            |
| »»» W            | boolean      | false | none |        | none                                                                                            |
| »»» E            | boolean      | false | none |        | none                                                                                            |
| » exit             | object       | false | none |        | 出口                                                                                            |
| »» X              | number       | true  | none |        | 坐标X（格）                                                                                     |
| »» Y              | number       | true  | none |        | 坐标Y（格）                                                                                     |
| »» facing         | string       | true  | none |        | 朝向                                                                                            |
| »» next_scene     | string¦null | false | none |        | 下一关场景路径 .tscn                                                                            |
| »» tooltip_offset | any          | false | none |        | 提示偏移（单位：像素）                                                                          |

anyOf

| 名称                | 类型      | 必选  | 约束 | 中文名 | 说明  |
| ------------------- | --------- | ----- | ---- | ------ | ----- |
| »»»*anonymous* | [integer] | false | none |        | [x,y] |

or

| 名称                | 类型   | 必选  | 约束 | 中文名 | 说明 |
| ------------------- | ------ | ----- | ---- | ------ | ---- |
| »»»*anonymous* | object | false | none |        | none |
| »»»» x          | string | true  | none |        | none |
| »»»» y          | string | true  | none |        | none |

continued

| 名称 | 类型    | 必选  | 约束 | 中文名 | 说明                         |
| ---- | ------- | ----- | ---- | ------ | ---------------------------- |
| item | [anyOf] | false | none |        | 物体数组<br />字段名可为复数 |

anyOf

| 名称            | 类型                                       | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------------------------------------------ | ----- | ---- | ------ | ---- |
| »*anonymous* | [ButtonController](#schemabuttoncontroller) | false | none |        | none |

or

| 名称            | 类型                                 | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------------------------------------ | ----- | ---- | ------ | ---- |
| »*anonymous* | [FakableButton](#schemafakablebutton) | false | none |        | none |

or

| 名称            | 类型                             | 必选  | 约束 | 中文名 | 说明 |
| --------------- | -------------------------------- | ----- | ---- | ------ | ---- |
| »*anonymous* | [FakableWall](#schemafakablewall) | false | none |        | none |

or

| 名称            | 类型                             | 必选  | 约束 | 中文名 | 说明 |
| --------------- | -------------------------------- | ----- | ---- | ------ | ---- |
| »*anonymous* | [FakableBomb](#schemafakablebomb) | false | none |        | none |

or

| 名称            | 类型               | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ------------------ | ----- | ---- | ------ | ---- |
| »*anonymous* | [Clue](#schemaclue) | false | none |        | none |

or

| 名称            | 类型                         | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ---------------------------- | ----- | ---- | ------ | ---- |
| »*anonymous* | [MapMirror](#schemamapmirror) | false | none |        | none |

continued

| 名称      | 类型    | 必选  | 约束 | 中文名 | 说明                         |
| --------- | ------- | ----- | ---- | ------ | ---------------------------- |
| character | [anyOf] | false | none |        | 角色数组<br />字段名可为复数 |

anyOf

| 名称            | 类型                   | 必选  | 约束 | 中文名 | 说明 |
| --------------- | ---------------------- | ----- | ---- | ------ | ---- |
| »*anonymous* | [Player](#schemaplayer) | false | none |        | 玩家 |

or

| 名称            | 类型                           | 必选  | 约束 | 中文名 | 说明                  |
| --------------- | ------------------------------ | ----- | ---- | ------ | --------------------- |
| »*anonymous* | [DolosBlack](#schemadolosblack) | false | none |        | 关卡向导<br />NPC之一 |

continued

| 名称  | 类型     | 必选  | 约束 | 中文名 | 说明                         |
| ----- | -------- | ----- | ---- | ------ | ---------------------------- |
| event | [object] | false | none |        | 事件数组<br />字段名可为复数 |

#### 枚举值

| 属性   | 值 |
| ------ | -- |
| facing | N  |
| facing | S  |
| facing | W  |
| facing | E  |
| facing | N  |
| facing | S  |
| facing | W  |
| facing | E  |
