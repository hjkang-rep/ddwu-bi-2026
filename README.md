# 빅데이터와 비즈니스인텔리전스 실습 저장소

동덕여자대학교 2026학년도 2학기 「빅데이터와 비즈니스인텔리전스」 실습용 저장소입니다.

## 여는 법 (GitHub Codespaces)

1. GitHub에 로그인합니다.
2. 이 페이지 위쪽의 초록색 **Code** 단추 → **Codespaces** 탭 → **Create codespace on main**을 누릅니다.
3. 2~3분 기다리면 브라우저 안에 VS Code가 열립니다. 처음 한 번만 오래 걸립니다.
4. 다음 수업부터는 <https://github.com/codespaces> 에서 만들어 둔 codespace를 눌러 엽니다. 새로 만들지 않습니다.

## 폴더

| 경로 | 내용 |
|---|---|
| `data/seoul_sales.db` | SQLite 파일 (표 `sales`, 215,232행) |
| `data/seoul_sales_2024_2026.csv` | 같은 자료의 CSV (AI 도구에 올릴 때) |
| `data/seoul_sales_2025.csv` | 2025년만 (파일 크기 한도가 작은 AI 도구용) |
| `week09/` | 9주차 실습 파일 |
| `내작업/` | 여러분이 만든 파일을 두는 곳 |

## 설치된 도구 (codespace를 만들 때 자동 설치)

| 확장 | 하는 일 |
|---|---|
| SQLTools + SQLite 드라이버 | `seoul_sales` 연결이 미리 만들어져 있음. 표 · 열 이름 자동 완성, 쿼리 실행과 결과 표 |
| SQLite (alexcvzz) | `.sql` 파일에서 오른쪽 클릭 → Run Query (예비 방법) |
| SQLite Viewer | `.db` 파일의 표 내용 보기 |
| Rainbow CSV | CSV 열 색 구분 |
| Data Wrangler · Jupyter | CSV · 데이터프레임을 표로 보고, 거르기 · 정렬을 pandas 코드로 |
| Python · Pylance | 파이썬 실행, 자동 완성 |
| Error Lens | 오류 메시지를 줄 옆에 표시 |
| GitHub Copilot Chat · Codex | AI에게 질문, 코드 설명 · 작성 |

이미 만든 codespace에 새 확장이 없으면 `F1` → **Codespaces: Rebuild Container**를 실행합니다(내 파일은 남음).

## AI 도구

- **GitHub Copilot Chat**: GitHub 로그인만으로 바로 쓸 수 있습니다. 학생 인증을 하면 무료입니다.
- **Codex(OpenAI)**: 확장이 미리 설치되어 있습니다. 화면 **오른쪽 사이드바**(Copilot Chat과 같은 자리)에 Codex 탭으로 뜹니다. 안 보이면 `Ctrl+Shift+P` → **Open Codex Sidebar**를 실행합니다. 처음 한 번 **본인의 ChatGPT 계정**으로 로그인합니다(기기 코드 로그인 권장). 로그인 정보는 내 codespace 안에 남으므로 다음 수업에 다시 로그인하지 않아도 됩니다. 로그인 정보는 다른 사람과 공유하지 않습니다.

## 새 주차 파일 받기

왼쪽의 **소스 제어** 아이콘 → **동기화**를 누르거나, 터미널에서 `git pull`을 실행합니다.
여러분의 파일은 `내작업/` 폴더에 두면 새 파일을 받을 때 섞이지 않습니다.

## 데이터 출처

서울시 상권분석서비스(추정매출-상권), 서울열린데이터광장 OA-15572, 제공 서울신용보증재단, 공공누리 제1유형(출처표시).
2024 · 2025년은 공개 파일, 2026년 1 · 2분기는 서울시 Open API로 받아 수업에 필요한 23개 열만 남겼습니다.
`당월_매출_금액`은 분기 매출(개인 + 법인)이며, 성별 · 연령 매출에는 법인 매출이 들어 있지 않습니다.
