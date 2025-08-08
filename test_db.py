import os
import asyncio
import re
from urllib.parse import urlsplit, urlunsplit, parse_qsl, urlencode
from sqlalchemy import text
from dotenv import load_dotenv
from sqlalchemy.ext.asyncio import create_async_engine

load_dotenv()

def _sanitize_db_url(url: str) -> str:
    # Remove sslmode and channel_binding from query to avoid asyncpg unexpected kw error
    parts = urlsplit(url)
    query_pairs = [(k, v) for k, v in parse_qsl(parts.query, keep_blank_values=True)
                   if k not in ("sslmode", "channel_binding")]
    sanitized_query = urlencode(query_pairs)
    return urlunsplit((parts.scheme, parts.netloc, parts.path, sanitized_query, parts.fragment))

async def async_main() -> None:
    database_url = os.getenv('DATABASE_URL')
    if not database_url:
        raise RuntimeError('DATABASE_URL is not set')

    database_url = _sanitize_db_url(database_url)
    async_url = re.sub(r'^postgresql:', 'postgresql+asyncpg:', database_url)

    # Enforce SSL for asyncpg explicitly
    engine = create_async_engine(async_url, echo=True, connect_args={"ssl": True})
    async with engine.connect() as conn:
        result = await conn.execute(text("select 'hello world'"))
        print(result.fetchall())
    await engine.dispose()

if __name__ == '__main__':
    asyncio.run(async_main()) 