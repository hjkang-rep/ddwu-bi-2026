-- =====================================================================
--  빅데이터와 비즈니스인텔리전스 (2026-2) 나눠 볼 때의 착시 실습  week11/pitfalls.sql
--  서울시 상권분석서비스(추정매출-상권) (서울열린데이터광장 OA-15572, 서울신용보증재단)
--
--  사용법 (codespace)
--   1) 쿼리를 SELECT 또는 WITH부터 ; 까지 마우스로 끌어 선택 -> 오른쪽 클릭 -> Run Query 바로 아래의 Run Selected Query
--      처음 한 번은 데이터베이스로 data/seoul_sales.db를 고름. 결과 창이 비어 있으면 한 번 더 실행
--   2) 터미널: sqlite3 -header -column data/seoul_sales.db < week11/pitfalls.sql   ([1]~[11]을 한꺼번에 실행)
--
--  [1]~[7]은 수업 설명에 나오는 쿼리, [8]~[11]은 실습 Q1~Q4에서 먼저 실행하는 쿼리.
--  주: 당월_매출_금액은 분기 매출(개인 + 법인, 원). 2026년은 2분기까지만 있음.
-- =====================================================================


-- [1] 컴퓨터및주변장치판매의 건당 금액: 2025년 상반기와 2026년 상반기 ======
WITH b AS (
  SELECT 상권_구분_코드_명 AS 구분,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2025 THEN 당월_매출_금액 END) AS 매출25,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2025 THEN 당월_매출_건수 END) AS 건수25,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2026 THEN 당월_매출_금액 END) AS 매출26,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2026 THEN 당월_매출_건수 END) AS 건수26
  FROM   sales
  WHERE  서비스_업종_코드_명 = '컴퓨터및주변장치판매'
    AND  기준_년분기_코드 IN (20251, 20252, 20261, 20262)
  GROUP BY 상권_구분_코드_명
), a AS (
  SELECT * FROM b
  UNION ALL
  SELECT '전체', SUM(매출25), SUM(건수25), SUM(매출26), SUM(건수26) FROM b
)
SELECT 구분,
       ROUND(1.0 * 매출25 / 건수25) AS 건당_25상반,
       ROUND(1.0 * 매출26 / 건수26) AS 건당_26상반,
       ROUND(100.0 * (1.0 * 매출26 / 건수26) / (1.0 * 매출25 / 건수25) - 100, 1) AS 증감,
       ROUND(100.0 * 건수25 / (SELECT SUM(건수25) FROM b), 1) AS 건수비중_25,
       ROUND(100.0 * 건수26 / (SELECT SUM(건수26) FROM b), 1) AS 건수비중_26
FROM   a;


-- [2] 건수 구성을 2025년 상반기로 고정한 2026년 상반기 건당 금액 ==========
WITH b AS (
  SELECT 상권_구분_코드_명 AS 구분,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2025 THEN 당월_매출_금액 END) AS 매출25,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2025 THEN 당월_매출_건수 END) AS 건수25,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2026 THEN 당월_매출_금액 END) AS 매출26,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2026 THEN 당월_매출_건수 END) AS 건수26
  FROM   sales
  WHERE  서비스_업종_코드_명 = '컴퓨터및주변장치판매'
    AND  기준_년분기_코드 IN (20251, 20252, 20261, 20262)
  GROUP BY 상권_구분_코드_명
)
SELECT ROUND(1.0 * SUM(매출25) / SUM(건수25)) AS 실제_25상반,
       ROUND(1.0 * SUM(매출26) / SUM(건수26)) AS 실제_26상반,
       ROUND(SUM(건수25 * (1.0 * 매출26 / 건수26)) / SUM(건수25)) AS 구성고정_26상반
FROM   b;


-- [3] 한식음식점과 청과상의 주말 비중: 상권 구분별과 전체 (2025년) ========
WITH b AS (
  SELECT 서비스_업종_코드_명 AS 업종,
         상권_구분_코드_명   AS 구분,
         SUM(당월_매출_금액) AS 매출,
         SUM(주말_매출_금액) AS 주말
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
    AND  서비스_업종_코드_명 IN ('한식음식점', '청과상')
  GROUP BY 서비스_업종_코드_명, 상권_구분_코드_명
), a AS (
  SELECT * FROM b
  UNION ALL
  SELECT 업종, '전체', SUM(매출), SUM(주말) FROM b GROUP BY 업종
)
SELECT 구분,
       ROUND(100.0 * SUM(CASE WHEN 업종 = '한식음식점' THEN 주말 END)
             / SUM(CASE WHEN 업종 = '한식음식점' THEN 매출 END), 1) AS 한식_주말,
       ROUND(100.0 * SUM(CASE WHEN 업종 = '청과상' THEN 주말 END)
             / SUM(CASE WHEN 업종 = '청과상' THEN 매출 END), 1)     AS 청과_주말,
       ROUND(100.0 * SUM(CASE WHEN 업종 = '한식음식점' THEN 매출 END)
             / (SELECT SUM(매출) FROM b WHERE 업종 = '한식음식점'), 1) AS 한식_매출비중,
       ROUND(100.0 * SUM(CASE WHEN 업종 = '청과상' THEN 매출 END)
             / (SELECT SUM(매출) FROM b WHERE 업종 = '청과상'), 1)     AS 청과_매출비중
FROM   a
GROUP BY 구분
ORDER BY CASE 구분 WHEN '전체' THEN 9 ELSE 1 END, 구분;


-- [4] 수산물판매의 여성 비중: 합계의 비율과 상권별 비율의 평균 (2025년) ====
WITH s AS (
  SELECT 상권_코드,
         SUM(여성_매출_금액) AS 여성,
         SUM(남성_매출_금액 + 여성_매출_금액) AS 개인
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
    AND  서비스_업종_코드_명 = '수산물판매'
  GROUP BY 상권_코드
  HAVING SUM(남성_매출_금액 + 여성_매출_금액) > 0
)
SELECT COUNT(*)                           AS 상권수,
       ROUND(100.0 * SUM(여성) / SUM(개인), 1) AS 합계의_비율,
       ROUND(AVG(100.0 * 여성 / 개인), 1) AS 비율의_평균
FROM   s;


-- [5] 2024 -> 2025 매출 증감률 상위 5개 칸 (상권 하나 · 업종 하나) ========
WITH y AS (
  SELECT MAX(상권_코드_명) AS 상권_코드_명, 서비스_업종_코드_명,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2024 THEN 당월_매출_금액 END) AS 매출24,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2025 THEN 당월_매출_금액 END) AS 매출25
  FROM   sales
  WHERE  기준_년분기_코드 / 10 IN (2024, 2025)
  GROUP BY 상권_코드, 서비스_업종_코드_명
)
SELECT 상권_코드_명, 서비스_업종_코드_명,
       매출24, 매출25,
       ROUND(100.0 * 매출25 / 매출24 - 100) AS 증감률
FROM   y
WHERE  매출24 > 0 AND 매출25 > 0
ORDER BY 증감률 DESC
LIMIT 5;


-- [6] 2024년 매출 규모 구간별 증감률의 퍼짐 (상권 하나 · 업종 하나인 칸) ====
WITH y AS (
  SELECT 상권_코드, 서비스_업종_코드_명,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2024 THEN 당월_매출_금액 END) AS 매출24,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2025 THEN 당월_매출_금액 END) AS 매출25
  FROM   sales
  WHERE  기준_년분기_코드 / 10 IN (2024, 2025)
  GROUP BY 상권_코드, 서비스_업종_코드_명
), g AS (
  SELECT CASE WHEN 매출24 < 1e8  THEN '1. 1억 미만'
              WHEN 매출24 < 1e9  THEN '2. 1~10억'
              WHEN 매출24 < 1e10 THEN '3. 10~100억'
              ELSE '4. 100억 이상' END AS 규모,
         100.0 * 매출25 / 매출24 - 100 AS 증감률
  FROM   y
  WHERE  매출24 > 0 AND 매출25 > 0
)
SELECT 규모,
       COUNT(*) AS 칸수,
       ROUND(100.0 * SUM(ABS(증감률) > 50) / COUNT(*), 1) AS 절반넘게_변한_비율
FROM   g
GROUP BY 규모
ORDER BY 규모;


-- [7] 상권별 호프-간이주점 매출과 편의점 매출의 관계 (2025년) =============
--     r제곱을 계산함. 상관계수 r은 그 제곱근이고 부호는 매출끼리_부호 · 비중끼리_부호 열로 봄
WITH p AS (
  SELECT 상권_코드,
         SUM(CASE WHEN 서비스_업종_코드_명 = '호프-간이주점' THEN 당월_매출_금액 END) / 1e8 AS x,
         SUM(CASE WHEN 서비스_업종_코드_명 = '편의점'        THEN 당월_매출_금액 END) / 1e8 AS y,
         SUM(당월_매출_금액) / 1e8 AS 전체
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
  GROUP BY 상권_코드
), d AS (
  SELECT x, y, x / 전체 AS xr, y / 전체 AS yr
  FROM   p
  WHERE  x > 0 AND y > 0
), c AS (
  SELECT COUNT(*)                         AS 상권수,
         AVG(x * y) - AVG(x) * AVG(y)     AS 공분산,
         AVG(x * x) - AVG(x) * AVG(x)     AS 분산x,
         AVG(y * y) - AVG(y) * AVG(y)     AS 분산y,
         AVG(xr * yr) - AVG(xr) * AVG(yr) AS 공분산r,
         AVG(xr * xr) - AVG(xr) * AVG(xr) AS 분산xr,
         AVG(yr * yr) - AVG(yr) * AVG(yr) AS 분산yr
  FROM   d
)
SELECT 상권수,
       ROUND(공분산 * 공분산 / (분산x * 분산y), 3)     AS 매출끼리_r제곱,
       CASE WHEN 공분산 > 0 THEN '+' ELSE '-' END      AS 매출끼리_부호,
       ROUND(공분산r * 공분산r / (분산xr * 분산yr), 3) AS 비중끼리_r제곱,
       CASE WHEN 공분산r > 0 THEN '+' ELSE '-' END     AS 비중끼리_부호
FROM   c;


-- [8] 실습 Q1: 일반의원과 육류판매의 2025년 건당 금액 (전체) ==============
SELECT 서비스_업종_코드_명,
       ROUND(SUM(당월_매출_금액) / 1e8) AS 매출_억,
       SUM(당월_매출_건수)              AS 건수,
       ROUND(1.0 * SUM(당월_매출_금액) / SUM(당월_매출_건수)) AS 건당_금액
FROM   sales
WHERE  기준_년분기_코드 / 10 = 2025
  AND  서비스_업종_코드_명 IN ('일반의원', '육류판매')
GROUP BY 서비스_업종_코드_명
ORDER BY 건당_금액 DESC;


-- [9] 실습 Q2: 치킨전문점의 2025년 주말 비중 (합계의 비율) ================
SELECT ROUND(SUM(당월_매출_금액) / 1e8) AS 매출_억,
       COUNT(DISTINCT 상권_코드)        AS 상권수,
       ROUND(100.0 * SUM(주말_매출_금액) / SUM(당월_매출_금액), 1) AS 주말_비중
FROM   sales
WHERE  기준_년분기_코드 / 10 = 2025
  AND  서비스_업종_코드_명 = '치킨전문점';


-- [10] 실습 Q3: 2024 -> 2025 상권별 매출 증감률 상위 5개 (조건 없음) ========
WITH y AS (
  SELECT 상권_코드, MAX(상권_코드_명) AS 상권_코드_명,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2024 THEN 당월_매출_금액 END) AS 매출24,
         SUM(CASE WHEN 기준_년분기_코드 / 10 = 2025 THEN 당월_매출_금액 END) AS 매출25
  FROM   sales
  WHERE  기준_년분기_코드 / 10 IN (2024, 2025)
  GROUP BY 상권_코드
)
SELECT 상권_코드_명,
       ROUND(매출24 / 1e8, 2) AS 매출24_억,
       ROUND(매출25 / 1e8, 2) AS 매출25_억,
       ROUND(100.0 * 매출25 / 매출24 - 100, 1) AS 증감률
FROM   y
WHERE  매출24 > 0 AND 매출25 > 0
ORDER BY 증감률 DESC
LIMIT 5;


-- [11] 실습 Q4: 20대 비중 4분위별 평균 심야 매출 비중 (2025년, 상권별) ======
WITH s AS (
  SELECT 상권_코드,
         100.0 * SUM(연령대_20_매출_금액)
               / SUM(남성_매출_금액 + 여성_매출_금액) AS 이십대,
         100.0 * SUM("시간대_21~24_매출_금액")
               / SUM(당월_매출_금액) AS 심야
  FROM   sales
  WHERE  기준_년분기_코드 / 10 = 2025
  GROUP BY 상권_코드
  HAVING SUM(남성_매출_금액 + 여성_매출_금액) > 0
), q AS (
  SELECT 이십대, 심야,
         NTILE(4) OVER (ORDER BY 이십대) AS 분위
  FROM   s
)
SELECT 분위,
       COUNT(*)              AS 상권수,
       ROUND(AVG(이십대), 1) AS 이십대_비중_평균,
       ROUND(AVG(심야), 1)   AS 심야_비중_평균
FROM   q
GROUP BY 분위
ORDER BY 분위;
