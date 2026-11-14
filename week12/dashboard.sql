-- =====================================================================
--  빅데이터와 비즈니스인텔리전스 (2026-2) 대시보드 설계 실습  week12/dashboard.sql
--  서울시 상권분석서비스(추정매출-상권) 2024년 1분기 ~ 2026년 2분기
--  (서울열린데이터광장 OA-15572, 서울신용보증재단)
--
--  업종: 커피-음료   기준 분기: 2026년 2분기(20262)   비교: 전년 같은 분기(20252)
--  대시보드의 카드 · 차트에 들어갈 숫자를 [1]~[11]에서 하나씩 계산함
--
--  사용법 (codespace)
--   1) 쿼리를 SELECT 또는 WITH부터 ; 까지 마우스로 끌어 선택 -> 오른쪽 클릭 -> Run Query 바로 아래의 Run Selected Query
--      처음 한 번은 데이터베이스로 data/seoul_sales.db를 고름. 결과 창이 비어 있으면 한 번 더 실행
--   2) 터미널: sqlite3 -header -column data/seoul_sales.db < week12/dashboard.sql   ([1]~[11]을 한꺼번에 실행)
--   3) 다른 업종으로 바꾸려면 이 파일을 내작업/w12_check.sql로 복사한 뒤
--      Ctrl+H로 '커피-음료'를 업종 이름으로 모두 바꿈. 업종 이름은 [1]의 결과에서 그대로 복사
--
--  주: 당월_매출_금액은 분기 매출(개인 + 법인, 원). 기준_년분기_코드 20262 = 2026년 2분기.
--      2026년은 2분기까지만 있음. 건당 금액 = 매출 합 / 건수 합.
-- =====================================================================


-- [1] 업종 확인: 기준 분기 매출 상위 15개 업종 (2026년 2분기, 억 원) ========
SELECT 서비스_업종_코드_명               AS 업종,
       ROUND(SUM(당월_매출_금액) / 1e8)   AS 매출_억,
       COUNT(DISTINCT 상권_코드)          AS 상권_수
FROM   sales
WHERE  기준_년분기_코드 = 20262
GROUP BY 서비스_업종_코드_명
ORDER BY 매출_억 DESC
LIMIT 15;


-- [2] 카드 숫자: 기준 분기와 전년 같은 분기 (커피-음료) =====================
SELECT 기준_년분기_코드                                   AS 분기,
       ROUND(SUM(당월_매출_금액) / 1e8, 1)                AS 매출_억,
       ROUND(SUM(당월_매출_건수) / 1e4)                   AS 건수_만,
       ROUND(1.0 * SUM(당월_매출_금액) / SUM(당월_매출_건수)) AS 건당_원,
       COUNT(DISTINCT 상권_코드)                          AS 상권_수,
       ROUND(100.0 * SUM(주말_매출_금액) / SUM(당월_매출_금액), 1) AS 주말_비중
FROM   sales
WHERE  서비스_업종_코드_명 = '커피-음료'
  AND  기준_년분기_코드 IN (20252, 20262)
GROUP BY 기준_년분기_코드
ORDER BY 기준_년분기_코드 DESC;


-- [3] 카드의 비교: 전년 같은 분기 대비 증감 (커피-음료, %와 %p) ==============
WITH k AS (
  SELECT 기준_년분기_코드             AS 분기,
         SUM(당월_매출_금액)          AS 매출,
         SUM(당월_매출_건수)          AS 건수,
         SUM(주말_매출_금액)          AS 주말
  FROM   sales
  WHERE  서비스_업종_코드_명 = '커피-음료'
    AND  기준_년분기_코드 IN (20252, 20262)
  GROUP BY 기준_년분기_코드
), c AS (SELECT * FROM k WHERE 분기 = 20262),
   p AS (SELECT * FROM k WHERE 분기 = 20252)
SELECT ROUND(100.0 * (c.매출 - p.매출) / p.매출, 1)             AS 매출_증감률,
       ROUND(100.0 * (c.건수 - p.건수) / p.건수, 1)             AS 건수_증감률,
       ROUND(100.0 * (1.0 * c.매출 / c.건수 - 1.0 * p.매출 / p.건수)
             / (1.0 * p.매출 / p.건수), 1)                     AS 건당_증감률,
       ROUND(100.0 * c.주말 / c.매출 - 100.0 * p.주말 / p.매출, 1) AS 주말_비중_차이
FROM   c, p;


-- [4] 추이 차트: 분기별 매출과 전년 같은 분기 대비 (커피-음료, 억 원) =========
WITH q AS (
  SELECT 기준_년분기_코드 AS 분기, SUM(당월_매출_금액) / 1e8 AS 매출_억
  FROM   sales
  WHERE  서비스_업종_코드_명 = '커피-음료'
  GROUP BY 기준_년분기_코드
)
SELECT 분기,
       ROUND(매출_억, 1)                                   AS 매출_억,
       ROUND(100.0 * (매출_억 - LAG(매출_억, 4) OVER (ORDER BY 분기))
             / LAG(매출_억, 4) OVER (ORDER BY 분기), 1)    AS 전년_대비
FROM   q
ORDER BY 분기;


-- [5] 비교 차트: 상권 구분별 매출 (커피-음료, 2026년 2분기와 전년 같은 분기) ==
WITH g AS (
  SELECT 상권_구분_코드_명 AS 구분,
         SUM(CASE WHEN 기준_년분기_코드 = 20262 THEN 당월_매출_금액 END) AS 기준,
         SUM(CASE WHEN 기준_년분기_코드 = 20252 THEN 당월_매출_금액 END) AS 비교
  FROM   sales
  WHERE  서비스_업종_코드_명 = '커피-음료'
  GROUP BY 상권_구분_코드_명
)
SELECT 구분,
       ROUND(기준 / 1e8, 1)                            AS 매출_억,
       ROUND(100.0 * 기준 / (SELECT SUM(기준) FROM g), 1) AS 비중,
       ROUND(100.0 * (기준 - 비교) / 비교, 1)          AS 전년_대비
FROM   g
ORDER BY 매출_억 DESC;


-- [6] 순위 차트: 매출 상위 10개 상권 (커피-음료, 2026년 2분기, 억 원) =========
SELECT 상권_코드_명                    AS 상권,
       상권_구분_코드_명               AS 구분,
       ROUND(당월_매출_금액 / 1e8, 1)  AS 매출_억
FROM   sales
WHERE  서비스_업종_코드_명 = '커피-음료'
  AND  기준_년분기_코드 = 20262
ORDER BY 당월_매출_금액 DESC
LIMIT 10;


-- [7] 구성 차트: 시간대별 매출 비중과 시간당 비중 (커피-음료, 2026년 2분기) ===
WITH t AS (
  SELECT SUM(당월_매출_금액)            AS 총,
         SUM("시간대_00~06_매출_금액") AS t00,
         SUM("시간대_06~11_매출_금액") AS t06,
         SUM("시간대_11~14_매출_금액") AS t11,
         SUM("시간대_14~17_매출_금액") AS t14,
         SUM("시간대_17~21_매출_금액") AS t17,
         SUM("시간대_21~24_매출_금액") AS t21
  FROM   sales
  WHERE  서비스_업종_코드_명 = '커피-음료'
    AND  기준_년분기_코드 = 20262
)
SELECT '00~06시' AS 시간대, ROUND(100.0 * t00 / 총, 1) AS 비중, ROUND(100.0 * t00 / 총 / 6, 1) AS 시간당 FROM t UNION ALL
SELECT '06~11시', ROUND(100.0 * t06 / 총, 1), ROUND(100.0 * t06 / 총 / 5, 1) FROM t UNION ALL
SELECT '11~14시', ROUND(100.0 * t11 / 총, 1), ROUND(100.0 * t11 / 총 / 3, 1) FROM t UNION ALL
SELECT '14~17시', ROUND(100.0 * t14 / 총, 1), ROUND(100.0 * t14 / 총 / 3, 1) FROM t UNION ALL
SELECT '17~21시', ROUND(100.0 * t17 / 총, 1), ROUND(100.0 * t17 / 총 / 4, 1) FROM t UNION ALL
SELECT '21~24시', ROUND(100.0 * t21 / 총, 1), ROUND(100.0 * t21 / 총 / 3, 1) FROM t;


-- [8] 분포: 상권별 매출의 평균 · 중앙값 · 상위 10% 비중 (커피-음료, 2026년 2분기) ==
WITH r AS (
  SELECT 당월_매출_금액 / 1e8 AS 매출_억,
         ROW_NUMBER() OVER (ORDER BY 당월_매출_금액 DESC) AS 순위,
         COUNT(*) OVER () AS n
  FROM   sales
  WHERE  서비스_업종_코드_명 = '커피-음료'
    AND  기준_년분기_코드 = 20262
)
SELECT COUNT(*)               AS 상권_수,
       ROUND(AVG(매출_억), 2) AS 평균_억,
       (SELECT ROUND(AVG(매출_억), 2) FROM r
         WHERE 순위 IN ((n + 1) / 2, (n + 2) / 2)) AS 중앙값_억,
       ROUND(100.0 * SUM(CASE WHEN 순위 <= n / 10 THEN 매출_억 END)
             / SUM(매출_억), 1) AS 상위10_비중
FROM   r;


-- [9] 필터 점검: 골목상권만 고른 카드 숫자 (커피-음료) =========================
SELECT 기준_년분기_코드                                   AS 분기,
       ROUND(SUM(당월_매출_금액) / 1e8, 1)                AS 매출_억,
       ROUND(SUM(당월_매출_건수) / 1e4)                   AS 건수_만,
       ROUND(1.0 * SUM(당월_매출_금액) / SUM(당월_매출_건수)) AS 건당_원,
       COUNT(DISTINCT 상권_코드)                          AS 상권_수,
       ROUND(100.0 * SUM(주말_매출_금액) / SUM(당월_매출_금액), 1) AS 주말_비중
FROM   sales
WHERE  서비스_업종_코드_명 = '커피-음료'
  AND  상권_구분_코드_명 = '골목상권'
  AND  기준_년분기_코드 IN (20252, 20262)
GROUP BY 기준_년분기_코드
ORDER BY 기준_년분기_코드 DESC;


-- [10] 건당 금액의 두 계산: 합계의 비율과 비율의 평균 (커피-음료, 2026년 2분기) ==
SELECT ROUND(1.0 * SUM(당월_매출_금액) / SUM(당월_매출_건수)) AS 합계의_비율,
       ROUND(AVG(1.0 * 당월_매출_금액 / 당월_매출_건수))      AS 비율의_평균,
       COUNT(*)                                             AS 행_수
FROM   sales
WHERE  서비스_업종_코드_명 = '커피-음료'
  AND  기준_년분기_코드 = 20262;


-- [11] 연도별 합계와 분기 수 (커피-음료). 2026년은 2개 분기뿐 ================
SELECT 기준_년분기_코드 / 10                AS 연도,
       COUNT(DISTINCT 기준_년분기_코드)     AS 분기_수,
       ROUND(SUM(당월_매출_금액) / 1e8)      AS 매출_억
FROM   sales
WHERE  서비스_업종_코드_명 = '커피-음료'
GROUP BY 기준_년분기_코드 / 10
ORDER BY 연도;
