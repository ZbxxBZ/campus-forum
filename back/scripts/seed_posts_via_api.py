#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import json
import urllib.request
import urllib.error

BASE = "http://localhost:8080/api/v1"


def call_json(method: str, url: str, token: str | None = None, payload: dict | None = None):
    data = None
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    if payload is not None:
        data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers=headers, method=method)
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="ignore")
        raise RuntimeError(f"HTTP {e.code} {url} => {body}") from e


def login(username: str, password: str) -> str:
    r = call_json("POST", f"{BASE}/auth/login", payload={"username": username, "password": password})
    if r.get("code") != 0:
        raise RuntimeError(f"登录失败 {username}: {r}")
    return r["data"]["token"]


def create_post(token: str, payload: dict) -> dict:
    r = call_json("POST", f"{BASE}/posts", token=token, payload=payload)
    if r.get("code") != 0:
        raise RuntimeError(f"发帖失败: {payload['title']} => {r}")
    return r["data"]["post"]


def approve(admin_token: str, post_id: int):
    r = call_json(
        "PATCH",
        f"{BASE}/posts/{post_id}/review",
        token=admin_token,
        payload={"action": "approve"},
    )
    if r.get("code") != 0:
        raise RuntimeError(f"审核失败 post_id={post_id}: {r}")


LONG_A = (
    "最近这段时间大家都在说“事情多、节奏快、容易焦虑”，我自己也是这样。后来我试着把每周任务拆成三类：必须做、最好做、可选做，"
    "发现效率提升很明显。必须做的先在上午完成，最好做的安排在精力还不错的时间段，可选做的放在晚上机动处理。这个方法看起来简单，"
    "但真正坚持下来后，压力会小很多。我们在校园里经常面临课程、活动、社团和个人安排同时推进的情况，如果没有节奏感，很容易被临时任务打乱。"
    "建议大家每周抽30分钟做一次小复盘：哪些事投入大但产出低，哪些方法值得保留。慢慢地就能形成适合自己的学习和生活系统。"
)

LONG_B = (
    "这篇内容想分享一个更贴近日常的经验：很多问题不是“不会做”，而是“没有稳定流程”。比如准备一次班级分享，大家常常临时找资料、"
    "临时做PPT、临时彩排，最后效果靠运气。其实可以固定成一个模板：先定目标受众，再列三到五个核心信息点，然后用案例去支撑，"
    "最后做一次10分钟演练。这个方法也适用于竞赛、社团活动和求职准备。流程化不代表死板，而是把注意力留给真正重要的部分。"
    "希望这篇帖子能给你一点启发，哪怕只改进一个小环节，也会让后续事情更顺畅。"
)


def gallery_payload(title: str, board_id: int, tags: list[str]) -> dict:
    return {
        "title": title,
        "summary": "用图文记录一次真实的校园过程，包含准备、执行和复盘三个阶段。",
        "content": (
            "这组图文记录的是一次很普通但很有代表性的校园日常：从前期准备到现场执行，再到结束后的复盘。"
            "我们把每个关键环节都写了中文说明，方便后来者直接参考。第一张是准备阶段，明确目标和分工；第二张是执行现场，重点看秩序和协作；"
            "第三张是过程中的问题处理；第四张是结果展示；第五张是复盘改进。希望这种“有过程、有细节”的记录方式，能比单纯晒图更有帮助。"
        ),
        "format": "image_gallery",
        "attachments": [
            f"https://picsum.photos/seed/{title}-1/1280/720",
            f"https://picsum.photos/seed/{title}-2/1280/720",
            f"https://picsum.photos/seed/{title}-3/1280/720",
            f"https://picsum.photos/seed/{title}-4/1280/720",
            f"https://picsum.photos/seed/{title}-5/1280/720",
        ],
        "galleryCaptions": [
            "准备阶段：明确目标与分工",
            "现场执行：控制节奏与沟通",
            "问题处理：快速定位并协同解决",
            "结果展示：重点信息清晰呈现",
            "复盘优化：记录经验与改进点",
        ],
        "tags": tags,
        "boardId": board_id,
        "visibility": "public",
    }


def main():
    accounts = [
        ("admin", "Admin123!"),
        ("teacher_li", "Teacher123!"),
        ("duanzhijie", "AAAjt123@"),
        ("张三", "zhangsan"),
    ]

    tokens = {}
    for u, p in accounts:
        tokens[u] = login(u, p)

    posts = {
        "admin": [
            {
                "title": "考试周自习室高效学习小技巧",
                "summary": "把考试周过成可控节奏，而不是临时抱佛脚。",
                "content": LONG_A + LONG_B,
                "format": "rich_text",
                "tags": ["期末", "学习方法", "时间管理"],
                "boardId": 1,
                "visibility": "public",
            },
            {
                "title": "校园活动组织复盘：为什么这次大家都愿意来",
                "summary": "从报名到现场执行，分享可复用的组织方式。",
                "content": "## 组织复盘\n\n" + LONG_A + "\n\n" + LONG_B,
                "format": "markdown",
                "tags": ["校园活动", "组织经验"],
                "boardId": 2,
                "visibility": "public",
            },
            {
                "title": "教育部最新通知阅读笔记（给同学的简版）",
                "summary": "把难懂的通知拆成可执行清单。",
                "content": LONG_A + LONG_B,
                "format": "external_link",
                "linkUrl": "https://www.moe.gov.cn/",
                "linkTitle": "教育部官网",
                "linkSummary": "建议优先阅读权威原文，再结合本帖执行清单。",
                "tags": ["通知解读", "政策阅读"],
                "boardId": 3,
                "visibility": "public",
            },
            gallery_payload("校园志愿活动现场记录", 7, ["志愿服务", "校园文化"]),
        ],
        "teacher_li": [
            {
                "title": "技术问答：小组项目总是延期，问题到底出在哪",
                "summary": "不是同学不努力，多数是协作流程没定好。",
                "content": LONG_B + LONG_A,
                "format": "rich_text",
                "tags": ["项目协作", "技术问答"],
                "boardId": 4,
                "visibility": "public",
            },
            {
                "title": "就业分享：简历怎么写才不空",
                "summary": "把做过什么写成解决了什么问题。",
                "content": "## 简历建议\n\n" + LONG_B + "\n\n" + LONG_A,
                "format": "markdown",
                "tags": ["求职", "简历", "面试"],
                "boardId": 5,
                "visibility": "public",
            },
            {
                "title": "给同学的一封温柔提醒：喜欢可以表达，边界也要尊重",
                "summary": "真诚和分寸感，应该同时在线。",
                "content": LONG_A + LONG_B,
                "format": "external_link",
                "linkUrl": "https://www.people.com.cn/",
                "linkTitle": "人民网",
                "linkSummary": "借助公开文章讨论理性沟通和边界感。",
                "tags": ["沟通", "边界感"],
                "boardId": 6,
                "visibility": "public",
            },
            gallery_payload("春季社团开放日图文记录", 2, ["社团", "校园生活"]),
        ],
        "duanzhijie": [
            {
                "title": "四六级备考：我从低效刷题到有节奏复习的转变",
                "summary": "重点不是题量，而是方法和复盘。",
                "content": LONG_A + LONG_B,
                "format": "rich_text",
                "tags": ["四六级", "英语学习"],
                "boardId": 1,
                "visibility": "public",
            },
            {
                "title": "校园贴吧热帖整理：本周同学最关心的三件事",
                "summary": "把讨论高频问题做成一页清单。",
                "content": "## 热点整理\n\n" + LONG_A + "\n\n" + LONG_B,
                "format": "markdown",
                "tags": ["校园贴吧", "热点"],
                "boardId": 7,
                "visibility": "public",
            },
            {
                "title": "求职信息辨别：哪些招聘信息要多看一眼",
                "summary": "避免看起来机会很多但信息质量不高。",
                "content": LONG_B + LONG_A,
                "format": "external_link",
                "linkUrl": "https://www.gov.cn/",
                "linkTitle": "中国政府网",
                "linkSummary": "建议结合官方渠道核验就业信息。",
                "tags": ["求职安全", "就业信息"],
                "boardId": 5,
                "visibility": "public",
            },
            gallery_payload("课堂与自习一周节奏图记", 1, ["学习节奏", "校园日常"]),
        ],
        "张三": [
            {
                "title": "宿舍关系小经验：把话说清楚比忍着更有效",
                "summary": "生活里很多矛盾，靠提前沟通就能减少。",
                "content": LONG_B + LONG_A,
                "format": "rich_text",
                "tags": ["宿舍生活", "沟通"],
                "boardId": 2,
                "visibility": "public",
            },
            {
                "title": "技术入门路线：从会写代码到会解决问题",
                "summary": "少一点照抄，多一点理解场景。",
                "content": "## 入门路线\n\n" + LONG_A + "\n\n" + LONG_B,
                "format": "markdown",
                "tags": ["技术成长", "学习路线"],
                "boardId": 4,
                "visibility": "public",
            },
            {
                "title": "校园公告看不懂？这份先看什么清单给你",
                "summary": "通知很多，但有优先级。",
                "content": LONG_A + LONG_B,
                "format": "external_link",
                "linkUrl": "https://www.xinhuanet.com/",
                "linkTitle": "新华网",
                "linkSummary": "配合公开信息，建立通知阅读优先级。",
                "tags": ["通知公告", "信息筛选"],
                "boardId": 3,
                "visibility": "public",
            },
            gallery_payload("傍晚校园跑步与学习平衡记录", 2, ["健康生活", "校园运动"]),
        ],
    }

    created = []
    admin_token = tokens["admin"]

    for u, _ in accounts:
        for payload in posts[u]:
            post = create_post(tokens[u], payload)
            created.append(post)

    for p in created:
        approve(admin_token, int(p["id"]))

    print(f"CREATED_COUNT={len(created)}")
    for p in created:
        print(f"{p['id']}\t{p['title']}\t{p.get('author','')}\t{p.get('format','')}\t{p.get('status','')}")


if __name__ == "__main__":
    main()
