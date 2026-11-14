# 빅데이터와 비즈니스인텔리전스 (2026-2) 업종 대시보드 기본판  week12/app_base.py
# 실행 (터미널, 저장소 맨 위 폴더에서):  python -m streamlit run week12/app_base.py
# 고쳐 쓰려면 먼저 복사:                 cp week12/app_base.py 내작업/w12_app.py
#
# 자료: 서울시 상권분석서비스 추정매출(서울열린데이터광장 OA-15572), data/seoul_sales.db의 표 sales
# 매출 = 당월_매출_금액(분기 합계, 개인 + 법인, 원). 건당 금액 = 매출 합 / 건수 합.

import sqlite3
from pathlib import Path

import pandas as pd
import streamlit as st

DB = Path(__file__).resolve().parent.parent / "data" / "seoul_sales.db"
st.set_page_config(page_title="업종 대시보드", layout="wide")


# [A] 자료 읽기: 처음 한 번만 읽고 결과를 기억해 둠(st.cache_data)
@st.cache_data
def load_data():
    con = sqlite3.connect(DB)
    df = pd.read_sql(
        """SELECT 기준_년분기_코드 AS 분기, 상권_구분_코드_명 AS 구분,
                  상권_코드, 상권_코드_명 AS 상권, 서비스_업종_코드_명 AS 업종,
                  당월_매출_금액 AS 매출, 당월_매출_건수 AS 건수,
                  주중_매출_금액 AS 주중, 주말_매출_금액 AS 주말
           FROM sales""",
        con,
    )
    con.close()
    return df


def 분기이름(q):
    return f"{q // 10}년 {q % 10}분기"


df = load_data()
기준 = int(df["분기"].max())  # 자료의 마지막 분기 (20262)
비교 = 기준 - 10              # 전년 같은 분기 (20252)

# [B] 필터: 왼쪽 사이드바
업종_목록 = sorted(df["업종"].unique())
업종 = st.sidebar.selectbox("업종", 업종_목록, index=업종_목록.index("커피-음료"))
구분_목록 = ["발달상권", "골목상권", "관광특구", "전통시장"]
구분 = st.sidebar.multiselect("상권 구분", 구분_목록, default=구분_목록)

d = df[(df["업종"] == 업종) & (df["구분"].isin(구분))]
now = d[d["분기"] == 기준]
before = d[d["분기"] == 비교]

st.title(f"{업종} 서울 상권 대시보드")
st.caption(
    f"기준 분기 {분기이름(기준)} · 비교: 전년 같은 분기({분기이름(비교)}) · "
    f"상권 구분: {', '.join(구분) if 구분 else '없음'}"
)

if now.empty:
    st.warning("고른 조건에 맞는 자료가 없습니다. 상권 구분을 하나 이상 고르세요.")
    st.stop()


# [C] 카드: 합계를 먼저 구한 뒤 나눔
def 증감률(a, b):
    return f"{100 * (a - b) / b:+.1f}%"


매출, 매출0 = now["매출"].sum(), before["매출"].sum()
건수, 건수0 = now["건수"].sum(), before["건수"].sum()
건당, 건당0 = 매출 / 건수, 매출0 / 건수0
상권수, 상권수0 = now["상권_코드"].nunique(), before["상권_코드"].nunique()

c1, c2, c3, c4 = st.columns(4)
c1.metric("매출", f"{매출 / 1e8:,.0f}억 원", 증감률(매출, 매출0), border=True)
c2.metric("결제 건수", f"{건수 / 1e4:,.0f}만 건", 증감률(건수, 건수0), border=True)
c3.metric("건당 금액", f"{건당:,.0f}원", 증감률(건당, 건당0), border=True)
c4.metric("매출이 있는 상권 수", f"{상권수:,}곳",
          f"{상권수 - 상권수0:+,}곳", border=True)

# [D] 추이 차트: 분기별 매출(억 원)
st.subheader("분기별 매출 (억 원)")
추이 = d.groupby("분기")["매출"].sum() / 1e8
추이.index = [분기이름(q) for q in 추이.index]
st.line_chart(추이, x_label="분기", y_label="매출(억 원)", height=300)

# [E] 순위 차트: 기준 분기 매출 상위 10개 상권(억 원), 큰 순서
st.subheader(f"매출 상위 10개 상권 ({분기이름(기준)}, 억 원)")
상위 = (now.groupby("상권")["매출"].sum() / 1e8).nlargest(10).reset_index()
st.bar_chart(상위, x="상권", y="매출", horizontal=True, sort="-매출",
             y_label="", height=360)

st.caption(
    "자료: 서울시 상권분석서비스 추정매출(서울열린데이터광장 OA-15572, 서울신용보증재단). "
    "카드 결제 기반 추정 매출이며 분기 합계(개인 + 법인). 2026년은 2분기까지. "
    "건당 금액 = 매출 합 ÷ 건수 합. 증감은 전년 같은 분기 대비."
)
