#!/usr/bin/env python3
"""
ClickHouse Schema Extractor
--------------------------
Extracts and formats schemas from ClickHouse database.
"""
import requests
from datetime import datetime
from typing import List, Dict, Optional, Tuple
import sys
import logging
import os
from dataclasses import dataclass
from pathlib import Path
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s', datefmt='%Y-%m-%d %H:%M:%S')
logger = logging.getLogger(__name__)
@dataclass
class ConnectionConfig:
    """Database connection configuration."""
    host: str
    port: int
    user: str
    password: str    
    @property
    def base_url(self) -> str:
        return f"http://{self.host}:{self.port}"
class SQLFormatter:
    """Handles SQL formatting."""    
    @staticmethod
    def format_create_table(sql: str) -> str:
        """Format CREATE TABLE statement with proper formatting."""
        sql = sql.replace('\\n', '\n')
        sql = sql.replace('ENGINE = MergeTree', 'ENGINE = MergeTree()')  # Fix MergeTree syntax
        
        # Split by lines and clean
        lines = [line.strip() for line in sql.split('\n') if line.strip()]
        formatted_lines = []
        in_columns = False
        
        # Extract key fields if present
        key_fields = None
        for line in lines:
            if '(' in line and ')' in line and not line.startswith('(') and not line.endswith(')'):
                try:
                    key_part = line[line.index('(')+1:line.index(')')].strip()
                    if key_part:
                        key_fields = [f.strip() for f in key_part.split(',')]
                except:
                    pass
        
        # Format the CREATE TABLE statement
        for i, line in enumerate(lines):
            # Handle CREATE TABLE line
            if line.startswith('CREATE TABLE'):
                formatted_lines.append(line)
                continue
                
            # Start of columns definition
            if line.startswith('('):
                in_columns = True
                formatted_lines.append('(')
                continue
                
            # End of columns definition
            if line == ')' and in_columns:
                in_columns = False
                formatted_lines.append(')')
                continue
                
            # Column definitions
            if in_columns and not line.startswith(')'):
                formatted_lines.append(f"    {line}")
                continue
                
            # Handle ENGINE
            if line.startswith('ENGINE'):
                formatted_lines.append(line)
                continue
                
            # Handle PARTITION BY
            if line.startswith('PARTITION BY'):
                formatted_lines.append(line)
                continue
                
            # Handle ORDER BY
            if line.startswith('ORDER BY'):
                formatted_lines.append(line)
                continue
                
            # Handle SETTINGS
            if line.startswith('SETTINGS'):
                formatted_lines.append(line)
                continue
                
            # Handle PRIMARY KEY
            if line.startswith('PRIMARY KEY'):
                formatted_lines.append(line)
                continue
                
            # Skip duplicate key definitions
            if line.startswith('(') and key_fields and any(field in line for field in key_fields):
                continue
        
        # Fix table structure
        fixed_sql = '\n'.join(formatted_lines)
        
        # Add PARTITION BY if missing
        if 'PARTITION BY' not in fixed_sql and 'ENGINE = MergeTree()' in fixed_sql:
            engine_idx = fixed_sql.index('ENGINE = MergeTree()')
            partition_line = '\nPARTITION BY shopid'  # Default partition by shopid
            fixed_sql = fixed_sql[:engine_idx] + partition_line + fixed_sql[engine_idx:]
        
        # Add ORDER BY if present in original
        if '(' in sql and ')' in sql and 'ORDER BY' not in fixed_sql:
            try:
                key_part = sql[sql.index('(')+1:sql.index(')')].strip()
                if key_part:
                    fields = [f.strip() for f in key_part.split(',')]
                    if fields:
                        settings_idx = fixed_sql.index('SETTINGS') if 'SETTINGS' in fixed_sql else len(fixed_sql)
                        order_line = f"\nORDER BY ({', '.join(fields)})"
                        fixed_sql = fixed_sql[:settings_idx] + order_line + fixed_sql[settings_idx:]
            except:
                pass
        
        # Add PRIMARY KEY if ORDER BY exists but PRIMARY KEY missing
        if 'ORDER BY' in fixed_sql and 'PRIMARY KEY' not in fixed_sql:
            try:
                order_by = fixed_sql[fixed_sql.index('ORDER BY'):].split('\n')[0]
                fields = order_by.replace('ORDER BY', '').strip()
                settings_idx = fixed_sql.index('SETTINGS') if 'SETTINGS' in fixed_sql else len(fixed_sql)
                primary_key_line = f"\nPRIMARY KEY {fields}"
                fixed_sql = fixed_sql[:settings_idx] + primary_key_line + fixed_sql[settings_idx:]
            except:
                pass
        
        return fixed_sql
class SchemaExtractor:
    """Extracts schema information from ClickHouse."""    
    def __init__(self, config: ConnectionConfig):
        self.config = config
        self._test_connection()    
    def _execute_query(self, query: str) -> List[tuple]:
        """Execute a query and return results."""
        params = {
            'query': query,
            'user': self.config.user,
            'password': self.config.password
        }        
        try:
            response = requests.get(self.config.base_url, params=params)
            response.raise_for_status()
            return [tuple(line.strip().split('\t')) 
                   for line in response.text.strip().split('\n') 
                   if line.strip()]
        except requests.exceptions.RequestException as e:
            raise Exception(f"Query execution failed: {str(e)}")    
    def _test_connection(self):
        """Test database connection."""
        try:
            self._execute_query("SELECT 1")
            logger.info(f"Successfully connected to ClickHouse at {self.config.host}:{self.config.port}")
        except Exception as e:
            raise Exception(f"Connection failed: {str(e)}")    
    def get_databases(self) -> List[str]:
        """Get list of all databases excluding system ones."""
        try:
            databases = self._execute_query("SHOW DATABASES")
            db_list = [db[0] for db in databases 
                      if db[0] not in {'system', 'information_schema', 'INFORMATION_SCHEMA'}]
            logger.info(f"Found {len(db_list)} user databases")
            return db_list
        except Exception as e:
            raise Exception(f"Failed to get databases: {str(e)}")
    def get_tables(self, database: str) -> List[str]:
        """Get all tables in a database."""
        try:
            tables = self._execute_query(f"SHOW TABLES FROM {database}")
            return [table[0] for table in tables]
        except Exception as e:
            logger.error(f"Error getting tables for {database}: {str(e)}")
            return []
    def get_table_schema(self, database: str, table: str) -> Optional[str]:
        """Get CREATE TABLE statement with fixes."""
        try:
            schema = self._execute_query(f"SHOW CREATE TABLE {database}.{table}")[0][0]
            return SQLFormatter.format_create_table(schema)
        except Exception as e:
            logger.error(f"Error getting schema for {database}.{table}: {str(e)}")
            return None
class SchemaWriter:
    """Writes schema information to file."""    
    def __init__(self, extractor: SchemaExtractor):
        self.extractor = extractor
    def write_schema(self, output_path: Path) -> None:
        """Write complete schema to file."""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')        
        with output_path.open('w', encoding='utf-8', newline='\n') as f:
            f.write("-- ClickHouse Schema Backup\n")
            f.write(f"-- Generated at: {timestamp}\n")
            f.write(f"-- Host: {self.extractor.config.host}:{self.extractor.config.port}\n")            
            f.write("\n-- Required settings\n")
            f.write("SET allow_experimental_database_materialize_mysql = 1;\n")
            f.write("SET allow_experimental_database_atomic = 1;\n\n")            
            databases = self.extractor.get_databases()
            for database in databases:
                logger.info(f"Processing database: {database}")                
                try:
                    f.write(f"-- =====================================\n")
                    f.write(f"-- Database: {database}\n")
                    f.write(f"-- =====================================\n\n")
                    f.write(f"CREATE DATABASE IF NOT EXISTS {database};\n\n")                    
                    tables = self.extractor.get_tables(database)
                    if tables:
                        f.write(f"-- Tables for database: {database}\n\n")                        
                        for table in sorted(tables):
                            schema = self.extractor.get_table_schema(database, table)
                            if schema:
                                f.write(f"-- Create table: {table}\n")
                                f.write(f"DROP TABLE IF EXISTS {database}.{table};\n")
                                f.write(f"{schema};\n\n")
                    else:
                        f.write("-- No tables found in this database\n\n")                    
                except Exception as e:
                    logger.error(f"Error processing database {database}: {str(e)}")
                    f.write(f"-- Error processing database {database}: {str(e)}\n\n")
def main():
    """Main entry point."""
    config = ConnectionConfig(
        host=os.environ.get("CLICKHOUSE_HOST", "localhost"),
        port=int(os.environ.get("CLICKHOUSE_PORT", "18123")),
        user=os.environ["CLICKHOUSE_USER"],
        password=os.environ["CLICKHOUSE_PASSWORD"]
    )    
    try:
        extractor = SchemaExtractor(config)
        writer = SchemaWriter(extractor)        
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = Path(f'clickhouse_schema_backup_{timestamp}.sql')        
        writer.write_schema(output_file)        
        logger.info(f"Schema extraction completed successfully!")
        logger.info(f"Output file: {output_file}")        
    except Exception as e:
        logger.error(f"Error: {str(e)}")
        sys.exit(1)
if __name__ == "__main__":
    main()
