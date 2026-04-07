import sqlite3
from contextlib import contextmanager
from pathlib import Path

DB_PATH = Path(__file__).parent / "emotion_test.db"


def get_connection():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA journal_mode=WAL")
    return conn


@contextmanager
def db():
    conn = get_connection()
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


def init_db():
    with db() as conn:
        conn.executescript("""
            CREATE TABLE IF NOT EXISTS userInfo (
                uid TEXT PRIMARY KEY,
                basicInfo TEXT NOT NULL DEFAULT '',
                detailedInfo TEXT NOT NULL DEFAULT '',
                passingScore INTEGER,
                surveyId INTEGER
            );

            CREATE TABLE IF NOT EXISTS survey (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                uid TEXT NOT NULL UNIQUE,
                questionsJson TEXT NOT NULL,
                createdAt TEXT,
                creatorBasicInfo TEXT NOT NULL DEFAULT ''
            );

            CREATE TABLE IF NOT EXISTS event (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                answererUid TEXT NOT NULL,
                creatorUid TEXT NOT NULL,
                totalScore INTEGER NOT NULL,
                submitTime TEXT NOT NULL
            );
        """)


# ==================== userInfo ====================

def save_user_info(uid: str, basic_info: str, detailed_info: str, passing_score: int | None):
    with db() as conn:
        conn.execute(
            """INSERT INTO userInfo (uid, basicInfo, detailedInfo, passingScore)
               VALUES (?, ?, ?, ?)
               ON CONFLICT(uid) DO UPDATE SET
                 basicInfo=excluded.basicInfo,
                 detailedInfo=excluded.detailedInfo,
                 passingScore=excluded.passingScore""",
            (uid, basic_info, detailed_info, passing_score),
        )


def get_user_info(uid: str) -> dict | None:
    with db() as conn:
        row = conn.execute("SELECT * FROM userInfo WHERE uid = ?", (uid,)).fetchone()
        return dict(row) if row else None


def get_all_user_info() -> list[dict]:
    with db() as conn:
        rows = conn.execute("SELECT * FROM userInfo").fetchall()
        return [dict(r) for r in rows]


# ==================== survey ====================

def save_survey(uid: str, questions_json: str, created_at: str | None, creator_basic_info: str) -> int:
    with db() as conn:
        row = conn.execute("SELECT id FROM survey WHERE uid = ?", (uid,)).fetchone()
        if row:
            survey_id = row["id"]
            conn.execute(
                "UPDATE survey SET questionsJson=?, creatorBasicInfo=? WHERE uid=?",
                (questions_json, creator_basic_info, uid),
            )
        else:
            cur = conn.execute(
                "INSERT INTO survey (uid, questionsJson, createdAt, creatorBasicInfo) VALUES (?, ?, ?, ?)",
                (uid, questions_json, created_at, creator_basic_info),
            )
            survey_id = cur.lastrowid

        conn.execute(
            "UPDATE userInfo SET surveyId=? WHERE uid=?", (survey_id, uid)
        )
        return survey_id


def get_survey_by_uid(uid: str) -> dict | None:
    with db() as conn:
        row = conn.execute("SELECT * FROM survey WHERE uid = ?", (uid,)).fetchone()
        return dict(row) if row else None


def get_all_surveys() -> list[dict]:
    with db() as conn:
        rows = conn.execute("SELECT * FROM survey ORDER BY createdAt DESC").fetchall()
        return [dict(r) for r in rows]


def delete_survey_by_uid(uid: str):
    with db() as conn:
        conn.execute("DELETE FROM survey WHERE uid = ?", (uid,))
        conn.execute("UPDATE userInfo SET surveyId=NULL WHERE uid=?", (uid,))


def delete_all_surveys():
    with db() as conn:
        conn.execute("DELETE FROM survey")
        conn.execute("UPDATE userInfo SET surveyId=NULL")


# ==================== event ====================

def save_event(answerer_uid: str, creator_uid: str, total_score: int, submit_time: str):
    with db() as conn:
        row = conn.execute(
            "SELECT id FROM event WHERE answererUid=? AND creatorUid=?",
            (answerer_uid, creator_uid),
        ).fetchone()
        if row:
            conn.execute(
                "UPDATE event SET totalScore=?, submitTime=? WHERE answererUid=? AND creatorUid=?",
                (total_score, submit_time, answerer_uid, creator_uid),
            )
        else:
            conn.execute(
                "INSERT INTO event (answererUid, creatorUid, totalScore, submitTime) VALUES (?, ?, ?, ?)",
                (answerer_uid, creator_uid, total_score, submit_time),
            )


def get_events_by_answerer(answerer_uid: str) -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM event WHERE answererUid=? ORDER BY submitTime DESC",
            (answerer_uid,),
        ).fetchall()
        return [dict(r) for r in rows]


def get_events_by_creator(creator_uid: str) -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM event WHERE creatorUid=? ORDER BY submitTime DESC",
            (creator_uid,),
        ).fetchall()
        return [dict(r) for r in rows]


def get_events_by_answerer_and_creator(answerer_uid: str, creator_uid: str) -> list[dict]:
    with db() as conn:
        rows = conn.execute(
            "SELECT * FROM event WHERE answererUid=? AND creatorUid=? ORDER BY submitTime DESC",
            (answerer_uid, creator_uid),
        ).fetchall()
        return [dict(r) for r in rows]


def get_latest_event(answerer_uid: str) -> dict | None:
    with db() as conn:
        row = conn.execute(
            "SELECT * FROM event WHERE answererUid=? ORDER BY submitTime DESC LIMIT 1",
            (answerer_uid,),
        ).fetchone()
        return dict(row) if row else None


def get_all_events() -> list[dict]:
    with db() as conn:
        rows = conn.execute("SELECT * FROM event ORDER BY submitTime DESC").fetchall()
        return [dict(r) for r in rows]


def delete_events_by_creator(creator_uid: str):
    with db() as conn:
        conn.execute("DELETE FROM event WHERE creatorUid=?", (creator_uid,))


def delete_events_by_answerer(answerer_uid: str):
    with db() as conn:
        conn.execute("DELETE FROM event WHERE answererUid=?", (answerer_uid,))


def delete_all_events():
    with db() as conn:
        conn.execute("DELETE FROM event")
