/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License.  You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

grammar DDLStatement;

import Symbol, Keyword, SQLServerKeyword, Literals, BaseRule, DMLStatement;

createTable
    : CREATE TABLE tableName fileTableClause createDefinitionClause
    ;

createIndex
    : CREATE createIndexSpecification INDEX indexName ON tableName columnNamesWithSort
    ;

createFunction
    : CREATE (OR ALTER)? FUNCTION functionName funcParameters funcReturns
    ;

alterTable
    : ALTER TABLE tableName alterDefinitionClause (COMMA_ alterDefinitionClause)*
    ;

alterIndex
    : ALTER INDEX (indexName | ALL) ON tableName
    ;

dropTable
    : DROP TABLE ifExist? tableNames
    ;

dropIndex
    : DROP INDEX ifExist? indexName ON tableName
    ;

truncateTable
    : TRUNCATE TABLE tableName
    ;

fileTableClause
    : (AS FILETABLE)?
    ;

createDefinitionClause
    : createTableDefinitions partitionScheme fileGroup
    ;

createTableDefinitions
    : LP_ createTableDefinition (COMMA_ createTableDefinition)* (COMMA_ periodClause)? RP_
    ;

createTableDefinition
    : columnDefinition | computedColumnDefinition | columnSetDefinition | tableConstraint | tableIndex
    ;

columnDefinition
    : columnName dataType columnDefinitionOption* columnConstraints columnIndex?
    ;

columnDefinitionOption
    : FILESTREAM
    | COLLATE collationName
    | SPARSE
    | MASKED WITH LP_ FUNCTION EQ_ STRING_ RP_
    | (CONSTRAINT ignoredIdentifier)? DEFAULT expr
    | IDENTITY (LP_ NUMBER_ COMMA_ NUMBER_ RP_)?
    | NOT FOR REPLICATION
    | GENERATED ALWAYS AS ROW (START | END) HIDDEN_?
    | NOT? NULL
    | ROWGUIDCOL 
    | ENCRYPTED WITH encryptedOptions
    | columnConstraint (COMMA_ columnConstraint)*
    | columnIndex
    ;

encryptedOptions
    : LP_ COLUMN_ENCRYPTION_KEY EQ_ ignoredIdentifier COMMA_ ENCRYPTION_TYPE EQ_ (DETERMINISTIC | RANDOMIZED) COMMA_ ALGORITHM EQ_ STRING_ RP_
    ;

columnConstraint
    : (CONSTRAINT constraintName)? (primaryKeyConstraint | columnForeignKeyConstraint | checkConstraint)
    ;

computedColumnConstraint
    : (CONSTRAINT constraintName)? (primaryKeyConstraint | computedColumnForeignKeyConstraint | checkConstraint)
    ;

computedColumnForeignKeyConstraint
    : (FOREIGN KEY)? tableName (LP_ columnName RP_)? computedColumnForeignKeyOnAction*
    ;

computedColumnForeignKeyOnAction
    : ON DELETE (NO ACTION | CASCADE) | ON UPDATE NO ACTION | NOT FOR REPLICATION
    ;

primaryKeyConstraint
    : (primaryKey | UNIQUE) (diskTablePrimaryKeyConstraintOption | memoryTablePrimaryKeyConstraintOption)
    ;

diskTablePrimaryKeyConstraintOption
    : clusterOption? primaryKeyWithClause? primaryKeyOnClause?
    ;

clusterOption
    : CLUSTERED | NONCLUSTERED
    ;

primaryKeyWithClause
    : WITH (FILLFACTOR EQ_ NUMBER_ | LP_ indexOption (COMMA_ indexOption)* RP_)
    ;

primaryKeyOnClause
    : onSchemaColumn | onFileGroup | onString
    ;

onSchemaColumn
    : ON schemaName LP_ columnName RP_
    ;

onFileGroup
    : ON ignoredIdentifier
    ;

onString
    : ON STRING_
    ;

memoryTablePrimaryKeyConstraintOption
    : NONCLUSTERED
    | NONCLUSTERED HASH withBucket?
    ;

withBucket
    : WITH LP_ BUCKET_COUNT EQ_ NUMBER_ RP_
    ;

columnForeignKeyConstraint
    : (FOREIGN KEY)? REFERENCES tableName (LP_ columnName RP_)? foreignKeyOnAction*
    ;

foreignKeyOnAction
    : ON (DELETE | UPDATE) foreignKeyOn | NOT FOR REPLICATION
    ;

foreignKeyOn
    : NO ACTION | CASCADE | SET (NULL | DEFAULT)
    ;

checkConstraint
    : CHECK(NOT FOR REPLICATION)? LP_ expr RP_
    ;

columnIndex
    : INDEX indexName clusterOption? withIndexOption? indexOnClause? fileStreamOn?
    ;

withIndexOption
    : WITH LP_ indexOption (COMMA_ indexOption)* RP_
    ;

indexOnClause
    : onSchemaColumn | onFileGroup | onDefault
    ;

onDefault
    : ON DEFAULT
    ;

fileStreamOn
    : FILESTREAM_ON (ignoredIdentifier | schemaName | STRING_)
    ;

columnConstraints
    : (columnConstraint(COMMA_ columnConstraint)*)?
    ;

computedColumnDefinition
    : columnName AS expr (PERSISTED(NOT NULL)?)? computedColumnConstraint?
    ;

columnSetDefinition 
    : ignoredIdentifier IDENTIFIER_ COLUMN_SET FOR ALL_SPARSE_COLUMNS
    ;

tableConstraint 
    : (CONSTRAINT constraintName)? (tablePrimaryConstraint | tableForeignKeyConstraint | checkConstraint)
    ;

tablePrimaryConstraint
    : primaryKeyUnique (diskTablePrimaryConstraintOption | memoryTablePrimaryConstraintOption)
    ;

primaryKeyUnique
    : primaryKey | UNIQUE
    ;

diskTablePrimaryConstraintOption
    : clusterOption? columnNames primaryKeyWithClause? primaryKeyOnClause?
    ;

memoryTablePrimaryConstraintOption
    : NONCLUSTERED (columnNames | hashWithBucket)
    ;

hashWithBucket
    : HASH columnNames withBucket
    ;

tableForeignKeyConstraint
    : (FOREIGN KEY)? columnNames REFERENCES tableName columnNames foreignKeyOnAction*
    ;

tableIndex
    : INDEX indexName indexNameOption (WITH indexOptions)? indexOnClause? fileStreamOn?
    ;

indexNameOption
    : clusterOption? columnNames | CLUSTERED COLUMNSTORE | NONCLUSTERED? COLUMNSTORE columnNames
    ;

indexOptions
    : LP_ indexOption (COMMA_ indexOption)* RP_
    ;

periodClause
    : PERIOD FOR SYSTEM_TIME LP_ columnName COMMA_ columnName RP_
    ;

partitionScheme
    : (ON (schemaName LP_ columnName RP_ | ignoredIdentifier | STRING_))?
    ;

fileGroup
    : (TEXTIMAGE_ON (ignoredIdentifier | STRING_))? ((FILESTREAM_ON (schemaName) | ignoredIdentifier STRING_))? (WITH tableOptions)?
    ;

tableOptions
    : LP_ tableOption (COMMA_ tableOption)* RP_
    ;

tableOption
    : DATA_COMPRESSION EQ_ (NONE | ROW | PAGE) (ON PARTITIONS LP_ partitionExpressions RP_)?
    | FILETABLE_DIRECTORY EQ_ ignoredIdentifier
    | FILETABLE_COLLATE_FILENAME EQ_ (collationName | DATABASE_DEAULT)
    | FILETABLE_PRIMARY_KEY_CONSTRAINT_NAME EQ_ ignoredIdentifier
    | FILETABLE_STREAMID_UNIQUE_CONSTRAINT_NAME EQ_ ignoredIdentifier
    | FILETABLE_FULLPATH_UNIQUE_CONSTRAINT_NAME EQ_ ignoredIdentifier
    | SYSTEM_VERSIONING EQ_ ON onHistoryTableClause?
    | REMOTE_DATA_ARCHIVE EQ_ (ON tableStretchOptions? | OFF migrationState_)
    | tableOperationOption
    | distributionOption
    | dataWareHouseTableOption
    | dataDelectionOption
    ;

dataDelectionOption
    : DATA_DELETION = ON (LP_ FILTER_COLUMN EQ_ columnName COMMA_ RETENTION_PERIOD EQ_ historyRetentionPeriod)
    ;

tableStretchOptions
    : LP_ tableStretchOption (COMMA_ tableStretchOption)* RP_
    ;

tableStretchOption
    : (FILTER_PREDICATE EQ_ (NULL | functionCall) COMMA_)? MIGRATION_STATE EQ_ (OUTBOUND | INBOUND | PAUSED)
    ;

migrationState_
    : LP_ MIGRATION_STATE EQ_ PAUSED RP_
    ;

tableOperationOption
    : (MEMORY_OPTIMIZED EQ_ ON) | (DURABILITY EQ_ (SCHEMA_ONLY | SCHEMA_AND_DATA)) | (SYSTEM_VERSIONING EQ_ ON onHistoryTableClause?)
    ;

distributionOption
    : DISTRIBUTION EQ_ (HASH LP_ columnName RP_ | ROUND_ROBIN | REPLICATE) 
    ;

dataWareHouseTableOption
    : CLUSTERED COLUMNSTORE INDEX | HEAP | dataWareHousePartitionOption
    ;

dataWareHousePartitionOption
    : (PARTITION LP_ columnName RANGE (LEFT | RIGHT)? FOR VALUES LP_ simpleExpr (COMMA_ simpleExpr)* RP_ RP_)
    ;

createIndexSpecification
    : UNIQUE? clusterOption?
    ;

alterDefinitionClause
    : addColumnSpecification | modifyColumnSpecification | alterDrop | alterCheckConstraint | alterTrigger | alterSwitch | alterSet | alterTableOption | REBUILD
    ;

addColumnSpecification
    : (WITH (CHECK | NOCHECK))? ADD (alterColumnAddOptions | generatedColumnNamesClause)
    ;

modifyColumnSpecification
    : alterColumnOperation dataType (COLLATE collationName)? (NULL | NOT NULL)? SPARSE?
    ;

alterColumnOperation
    : ALTER COLUMN columnName
    ;

alterColumnAddOptions
    : alterColumnAddOption (COMMA_ alterColumnAddOption)*
    ;

alterColumnAddOption
    : columnDefinition
    | computedColumnDefinition
    | columnSetDefinition
    | tableConstraint
    | alterTableTableIndex
    | constraintForColumn
    ;

constraintForColumn
    : (CONSTRAINT constraintName)? DEFAULT simpleExpr FOR columnName
    ;

generatedColumnNamesClause
    : generatedColumnNameClause COMMA_ periodClause | periodClause COMMA_ generatedColumnNameClause
    ;

generatedColumnNameClause
    : generatedColumnName DEFAULT simpleExpr (WITH VALUES)? COMMA_ generatedColumnName
    ;

generatedColumnName
    : columnName dataTypeName GENERATED ALWAYS AS ROW (START | END)? HIDDEN_? (NOT NULL)? (CONSTRAINT ignoredIdentifier)?
    ;

alterDrop
    : DROP (alterTableDropConstraint | dropColumnSpecification | dropIndexSpecification | PERIOD FOR SYSTEM_TIME)
    ;

alterTableDropConstraint
    : CONSTRAINT? ifExist? dropConstraintName (COMMA_ dropConstraintName)*
    ;

dropConstraintName
    : constraintName dropConstraintWithClause?
    ;

dropConstraintWithClause
    : WITH LP_ dropConstraintOption (COMMA_ dropConstraintOption)* RP_
    ;

dropConstraintOption
    : (MAXDOP EQ_ NUMBER_ | ONLINE EQ_ onOffOption | MOVE TO (schemaName LP_ columnName RP_ | ignoredIdentifier | STRING_))
    ;

onOffOption
    : ON | OFF
    ;

dropColumnSpecification
    : COLUMN ifExist? columnName (COMMA_ columnName)*
    ;

dropIndexSpecification
    : INDEX ifExist? indexName (COMMA_ indexName)*
    ;

alterCheckConstraint 
    : WITH? (CHECK | NOCHECK) CONSTRAINT (ALL | constraintName)
    ;

alterTrigger 
    : (ENABLE| DISABLE) TRIGGER (ALL | ignoredIdentifiers)
    ;

alterSwitch
    : SWITCH (PARTITION expr)? TO tableName (PARTITION expr)? (WITH LP_ lowPriorityLockWait RP_)?
    ;

alterSet
    : SET LP_ (setFileStreamClause | setSystemVersionClause) RP_ 
    ;

setFileStreamClause
    : FILESTREAM_ON EQ_ (schemaName | ignoredIdentifier | STRING_)
    ;

setSystemVersionClause
    : SYSTEM_VERSIONING EQ_ (OFF | ON alterSetOnClause?)
    ;

alterSetOnClause
    : LP_ (HISTORY_TABLE EQ_ tableName)? dataConsistencyCheckClause? historyRetentionPeriodClause? RP_
    ;

dataConsistencyCheckClause
    : COMMA_? DATA_CONSISTENCY_CHECK EQ_ onOffOption
    ;

historyRetentionPeriodClause
    : COMMA_? HISTORY_RETENTION_PERIOD EQ_ historyRetentionPeriod
    ;

historyRetentionPeriod
    : INFINITE | (NUMBER_ (DAY | DAYS | WEEK | WEEKS | MONTH | MONTHS | YEAR | YEARS))
    ;

alterTableTableIndex
    : indexWithName (indexNonClusterClause | indexClusterClause)
    ;

indexWithName
    : INDEX indexName
    ;

indexNonClusterClause
    : NONCLUSTERED (hashWithBucket | columnNamesWithSort alterTableIndexOnClause?)
    ;

alterTableIndexOnClause
    : ON ignoredIdentifier | DEFAULT
    ;

indexClusterClause
    : CLUSTERED COLUMNSTORE (WITH COMPRESSION_DELAY EQ_ NUMBER_ MINUTES?)? indexOnClause?
    ;

alterTableOption
    : SET LP_ LOCK_ESCALATION EQ_ (AUTO | TABLE | DISABLE) RP_
    | MEMORY_OPTIMIZED EQ_ ON
    | DURABILITY EQ_ (SCHEMA_ONLY | SCHEMA_AND_DATA) 
    | SYSTEM_VERSIONING EQ_ ON onHistoryTableClause?
    ;

onHistoryTableClause
    : LP_ HISTORY_TABLE EQ_ tableName (COMMA_ DATA_CONSISTENCY_CHECK EQ_ onOffOption)? RP_
    ;

ifExist
    : IF EXISTS
    ;

declareVariable
    : DECLARE (variable (COMMA_ variable)* | tableVariable)
    ;

variable
    : variableName AS? dataType (EQ_ simpleExpr)?
    | variableName CURSOR
    ;

tableVariable
    : variableName AS? variTableTypeDefinition
    ;

variTableTypeDefinition
    : TABLE LP_ tableVariableClause (COMMA_ tableVariableClause)* RP_
    ;

tableVariableClause
    : variableTableColumnDefinition | variableTableConstraint
    ;

variableTableColumnDefinition
    : columnName (dataTypeName | AS expr) (COLLATE collationName)? ((DEFAULT expr)? | IDENTITY (LP_ NUMBER_ COMMA_ NUMBER_ RP_)?) ROWGUIDCOL? variableTableColumnConstraint
    ;

variableTableColumnConstraint
    : (NULL | NOT NULL)?
    | (PRIMARY KEY | UNIQUE)?
    | CHECK LP_ expr RP_
    | WITH indexOption
    ;

variableTableConstraint
    : (PRIMARY KEY | UNIQUE) LP_ columnName (COMMA_ columnName)* RP_
    | CHECK expr
    ;

setVariable
    : SET variableName setVariableClause
    ;

setVariableClause
    : (DOT_ identifier)? EQ_ (expr | identifier DOT_ identifier | NCHAR_TEXT)
    | compoundOperation expr
    | EQ_ cursorVariable
    | EQ_ LP_ select RP_
    ;

cursorVariable
    : variableName
    | CURSOR cursorClause FOR select (FOR (READ_ONLY | UPDATE (OF name (COMMA_ name)*)))
    ;

cursorClause
    : (FORWARD_ONLY | SCROLL)? (STATIC | KEYSET | DYNAMIC | FAST_FORWARD)? (READ_ONLY | SCROLL_LOCKS | OPTIMISTIC)? (TYPE_WARNING)?
    ;

compoundOperation
    : PLUS_ EQ_
    | MINUS_ EQ_
    | ASTERISK_ EQ_
    | SLASH_ EQ_
    | MOD_ EQ_
    | AMPERSAND_ EQ_
    | CARET_ EQ_
    | VERTICAL_BAR_ EQ_
    ;


funcParameters
    : LP_ (variableName AS? (owner DOT_)? dataType (EQ_ ignoredIdentifier)? READONLY?)* RP_
    ;

funcReturns
    : funcScalarReturn | funcInlineReturn | funcMutiReturn
    ;

funcMutiReturn
    : RETURNS variableName TABLE createTableDefinitions (WITH functionOption (COMMA_ functionOption)*)? AS? BEGIN compoundStatement RETURN END
    ;

funcInlineReturn
    : RETURNS TABLE (WITH functionOption (COMMA_ functionOption)*)? AS? RETURN LP_? select RP_?
    ;

funcScalarReturn
    : RETURNS dataType (WITH functionOption (COMMA_ functionOption)*)? AS? BEGIN compoundStatement RETURN expr
    ;

tableTypeDefinition
    : (columnDefinition columnConstraint | computedColumnDefinition) tableConstraint*
    ;

compoundStatement
    : validStatement*
    ;

functionOption
    : ENCRYPTION?
    | SCHEMABINDING?
    | (RETURNS NULL ON NULL INPUT | CALLED ON NULL INPUT)?
    | (EXECUTE AS CALLER)?
    | (INLINE = ( ON | OFF ))?
    ;

validStatement
    : (createTable | alterTable | dropTable | truncateTable| insert
    | update | delete | select | setVariable | declareVariable) SEMI_?
    ;
