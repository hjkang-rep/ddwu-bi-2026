-- =====================================================================
--  빅데이터와 비즈니스인텔리전스 (2026-2) 고객층 분석 실습  week11/customer.sql
--  서울시 상권분석서비스(추정매출-상권) 2025년 (서울열린데이터광장 OA-15572, 서울신용보증재단)
--
--  사용법 (codespace)
--   1) 쿼리를 SELECT 또는 WITH부터 ; 까지 마우스로 끌어 선택 -> 오른쪽 클릭 -> Run Query 바로 아래의 Run Selected Query
--      처음 한 번은 데이터베이스로 data/seoul_sales.db를 고름. 결과 창이 비어 있으면 한 번 더 실행
--   2) 터미널: sqlite3 -header -column data/seoul_sales.db < week11/customer.sql   ([1]~[10]을 한꺼번에 실행)
--   3) 실행 전에 쿼리가 무엇을 세는지 읽고 결과의 크기를 예측할 것
--
--  주: 당월_매출_금액은 분기 매출(개인 + 법인, 원). 기준_년분기_코드 20251 = 2025년 1분기.
--      남성 · 여성 · 연령대 열은 개인 매출만 담고 있어서 합해도 총매출보다 작음.
--      성별 · 연령대별 결제 건수 열과 요일별 열은 이 표에 없음.
-- =====================================================================


-- [1] 고객 열의 합 점검: 총매출과 구분별 합 (2025년, 조 원) ==============
SELECT ROUND(SUM(당월_매출_금액) / 1e12, 2) AS 총매출,
       ROUND(SUM(남성_매출_금액 + 여성_매출_금액)
             / 1e12, 2)                     AS 성별_합,
       ROUND(SUM(연령대_10_매출_금액 + 연령대_20_매출_금액
                 + 연령대_30_매출_금액 + 연령대_40_매출_금액
                 + 연령대_50_매출_금액 + 연령대_60_이상_매출_금액)
             / 1e12, 2)                     AS 연령대_합,
       ROUND(SUM(주중_매출_금액 + 주말_매출_금액)
             / 1e12, 2)                     AS 주중주말_합,
       ROUND(SUM("시간대_00~06_매출_금액" + "시간대_06~11_매출_금액"
                 + "시간대_11~14_매출_금액" + "시간대_14~17_매출_금액"
                 + "시간대_17~21_매출_금액" + "시간대_21~24_매출_금액")
             / 1e12, 2)                     AS 시간대_합
FROM   sales
WHERE  기준_년분기_코드 / 10 = 2025;


-- [2] 1단계 성별 구성: 서울 전체, 분모 두 가지 (2025년) ==================
WITH t AS (
  SELECT SUM(남성_매출_금액) AS 남성,
         SUM(여성_매출_금액) AS 여성,
         SUM(당월_매출_금액) AS 총매출
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
)
SELECT ROUND(남성 / 1e12, 2)           AS 남성_조,
       ROUND(여성 / 1e12, 2)           AS 여성_조,
       ROUND(100.0 * 여성 / 총매출, 1) AS 여성_총매출기준,
       ROUND(100.0 * 여성 / (남성 + 여성), 1) AS 여성_개인기준,
       ROUND(100.0 * (남성 + 여성) / 총매출, 1) AS 개인_비중
FROM   t;


-- [3] 1단계 업종별 여성 비중 상위 10개 (2025년, 매출 1천억 원 이상 업종) ====
WITH g AS (
  SELECT 서비스_업종_코드_명 AS 업종,
         SUM(당월_매출_금액) AS 매출,
         SUM(여성_매출_금액) AS 여성,
         SUM(남성_매출_금액 + 여성_매출_금액) AS 개인
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
  GROUP BY 서비스_업종_코드_명
)
SELECT 업종,
       ROUND(매출 / 1e8)             AS 매출_억,
       ROUND(100.0 * 여성 / 개인, 1) AS 여성_비중
FROM   g
WHERE  매출 >= 1e11
ORDER BY 여성_비중 DESC
LIMIT 10;


-- [4] 2단계 연령대 구성: 서울 전체 (2025년, 개인 매출 기준) ==============
WITH t AS (
  SELECT SUM(연령대_10_매출_금액)      AS a10,
         SUM(연령대_20_매출_금액)      AS a20,
         SUM(연령대_30_매출_금액)      AS a30,
         SUM(연령대_40_매출_금액)      AS a40,
         SUM(연령대_50_매출_금액)      AS a50,
         SUM(연령대_60_이상_매출_금액) AS a60
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
), u AS (
  SELECT '10대' AS 연령대, a10 AS 금액 FROM t UNION ALL
  SELECT '20대', a20 FROM t UNION ALL
  SELECT '30대', a30 FROM t UNION ALL
  SELECT '40대', a40 FROM t UNION ALL
  SELECT '50대', a50 FROM t UNION ALL
  SELECT '60대 이상', a60 FROM t
)
SELECT 연령대,
       ROUND(금액 / 1e12, 2) AS 매출_조,
       ROUND(100.0 * 금액 / (SELECT SUM(금액) FROM u), 1) AS 비중
FROM   u;


-- [5] 2단계 업종별 20대 비중과 지수 상위 10개 (2025년, 매출 1천억 원 이상) ==
WITH g AS (
  SELECT 서비스_업종_코드_명      AS 업종,
         SUM(당월_매출_금액)      AS 매출,
         SUM(연령대_20_매출_금액) AS 이십대,
         SUM(남성_매출_금액 + 여성_매출_금액) AS 개인
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
  GROUP BY 서비스_업종_코드_명
), seoul AS (
  SELECT 1.0 * SUM(이십대) / SUM(개인) AS 비중 FROM g
)
SELECT 업종,
       ROUND(매출 / 1e8)               AS 매출_억,
       ROUND(100.0 * 이십대 / 개인, 1) AS 이십대_비중,
       ROUND(100.0 * 이십대 / 개인 / seoul.비중) AS 지수
FROM   g, seoul
WHERE  매출 >= 1e11
ORDER BY 지수 DESC
LIMIT 10;


-- [6] 3단계 시간대 구성: 비중과 시간당 비중 (2025년) =====================
WITH t AS (
  SELECT SUM(당월_매출_금액)           AS 총,
         SUM("시간대_00~06_매출_금액") AS t00,
         SUM("시간대_06~11_매출_금액") AS t06,
         SUM("시간대_11~14_매출_금액") AS t11,
         SUM("시간대_14~17_매출_금액") AS t14,
         SUM("시간대_17~21_매출_금액") AS t17,
         SUM("시간대_21~24_매출_금액") AS t21
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
), u AS (
  SELECT '00~06' AS 시간대, 6 AS 시간수, t00 AS 금액, 총 FROM t UNION ALL
  SELECT '06~11', 5, t06, 총 FROM t UNION ALL
  SELECT '11~14', 3, t11, 총 FROM t UNION ALL
  SELECT '14~17', 3, t14, 총 FROM t UNION ALL
  SELECT '17~21', 4, t17, 총 FROM t UNION ALL
  SELECT '21~24', 3, t21, 총 FROM t
)
SELECT 시간대, 시간수,
       ROUND(100.0 * 금액 / 총, 1)          AS 비중,
       ROUND(100.0 * 금액 / 총 / 시간수, 1) AS 시간당_비중
FROM   u;


-- [7] 3단계 주중 · 주말: 비중과 하루당 매출 배수 (2025년) ================
WITH t AS (
  SELECT SUM(당월_매출_금액) AS 총,
         SUM(주중_매출_금액) AS 주중,
         SUM(주말_매출_금액) AS 주말
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
)
SELECT ROUND(100.0 * 주중 / 총, 1)           AS 주중_비중,
       ROUND(100.0 * 주말 / 총, 1)           AS 주말_비중,
       ROUND((주말 / 2.0) / (주중 / 5.0), 2) AS 주말_하루_배수
FROM   t;


-- [8] 4단계 상권별 20대 매출: 평균 · 중앙값 · 상위 10% 비중 (2025년) ======
WITH s AS (                          -- 상권별 1년 20대 매출(억 원)
  SELECT 상권_코드, SUM(연령대_20_매출_금액) / 1e8 AS 매출_억
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
  GROUP BY 상권_코드
), r AS (                            -- 큰 순서로 순위와 전체 상권 수
  SELECT 매출_억,
         ROW_NUMBER() OVER (ORDER BY 매출_억 DESC) AS 순위,
         COUNT(*) OVER () AS n
  FROM   s
)
SELECT COUNT(*)               AS 상권수,
       ROUND(AVG(매출_억), 2) AS 평균_억,
       (SELECT ROUND(AVG(매출_억), 2) FROM r
         WHERE 순위 IN ((n + 1) / 2, (n + 2) / 2))
                              AS 중앙값_억,
       ROUND(100.0 * SUM(CASE WHEN 순위 <= n / 10
                              THEN 매출_억 END)
             / SUM(매출_억), 1)
                              AS 상위10_비중
FROM   r;


-- [9] 4단계 20대 매출 상위 상권 5개 (2025년, 억 원) ======================
WITH s AS (
  SELECT 상권_코드_명, 상권_구분_코드_명,
         SUM(연령대_20_매출_금액) AS 이십대,
         SUM(남성_매출_금액 + 여성_매출_금액) AS 개인
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
  GROUP BY 상권_코드, 상권_코드_명, 상권_구분_코드_명
)
SELECT 상권_코드_명, 상권_구분_코드_명,
       ROUND(이십대 / 1e8)             AS 이십대_억,
       ROUND(100.0 * 이십대 / 개인, 1) AS 이십대_비중
FROM   s
ORDER BY 이십대_억 DESC
LIMIT 5;


-- [10] 5단계 업종 하나의 고객층 요약 (2025년). 내작업에 복사한 뒤 업종 이름만 바꾸어 실행 가능 ==
WITH b AS (
  SELECT SUM(당월_매출_금액)           AS 총,
         SUM(당월_매출_건수)           AS 건수,
         SUM(남성_매출_금액 + 여성_매출_금액) AS 개인,
         SUM(여성_매출_금액)           AS 여성,
         SUM(연령대_20_매출_금액)      AS a20,
         SUM(연령대_30_매출_금액)      AS a30,
         SUM(연령대_40_매출_금액)      AS a40,
         SUM(연령대_50_매출_금액)      AS a50,
         SUM(연령대_60_이상_매출_금액) AS a60,
         SUM(주중_매출_금액)           AS 주중,
         SUM(주말_매출_금액)           AS 주말,
         SUM("시간대_11~14_매출_금액") AS t11,
         SUM("시간대_14~17_매출_금액") AS t14,
         SUM("시간대_17~21_매출_금액") AS t17
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
    AND  서비스_업종_코드_명 = '미용실'
)
SELECT '매출(억 원)' AS 지표, ROUND(총 / 1e8) AS 값 FROM b UNION ALL
SELECT '건당 금액(원)', ROUND(1.0 * 총 / 건수) FROM b UNION ALL
SELECT '개인 매출 비중(%)', ROUND(100.0 * 개인 / 총, 1) FROM b UNION ALL
SELECT '여성 비중(%)', ROUND(100.0 * 여성 / 개인, 1) FROM b UNION ALL
SELECT '20대 비중(%)', ROUND(100.0 * a20 / 개인, 1) FROM b UNION ALL
SELECT '30대 비중(%)', ROUND(100.0 * a30 / 개인, 1) FROM b UNION ALL
SELECT '40대 비중(%)', ROUND(100.0 * a40 / 개인, 1) FROM b UNION ALL
SELECT '50대 비중(%)', ROUND(100.0 * a50 / 개인, 1) FROM b UNION ALL
SELECT '60대 이상 비중(%)', ROUND(100.0 * a60 / 개인, 1) FROM b UNION ALL
SELECT '주말 비중(%)', ROUND(100.0 * 주말 / 총, 1) FROM b UNION ALL
SELECT '주말 하루 배수', ROUND((주말 / 2.0) / (주중 / 5.0), 2) FROM b UNION ALL
SELECT '11~14시 비중(%)', ROUND(100.0 * t11 / 총, 1) FROM b UNION ALL
SELECT '14~17시 비중(%)', ROUND(100.0 * t14 / 총, 1) FROM b UNION ALL
SELECT '17~21시 비중(%)', ROUND(100.0 * t17 / 총, 1) FROM b;
