{*********************************************************}
{                                                         }
{                 Zeos Database Objects                   }
{       Test Case for Generic Metadata Classes            }
{                                                         }
{*********************************************************}

{@********************************************************}
{    Copyright (c) 1999-2006 Zeos Development Group       }
{                                                         }
{ License Agreement:                                      }
{                                                         }
{ This library is distributed in the hope that it will be }
{ useful, but WITHOUT ANY WARRANTY; without even the      }
{ implied warranty of MERCHANTABILITY or FITNESS FOR      }
{ A PARTICULAR PURPOSE.  See the GNU Lesser General       }
{ Public License for more details.                        }
{                                                         }
{ The source code of the ZEOS Libraries and packages are  }
{ distributed under the Library GNU General Public        }
{ License (see the file COPYING / COPYING.ZEOS)           }
{ with the following  modification:                       }
{ As a special exception, the copyright holders of this   }
{ library give you permission to link this library with   }
{ independent modules to produce an executable,           }
{ regardless of the license terms of these independent    }
{ modules, and to copy and distribute the resulting       }
{ executable under terms of your choice, provided that    }
{ you also meet, for each linked independent module,      }
{ the terms and conditions of the license of that module. }
{ An independent module is a module which is not derived  }
{ from or based on this library. If you modify this       }
{ library, you may extend this exception to your version  }
{ of the library, but you are not obligated to do so.     }
{ If you do not wish to do so, delete this exception      }
{ statement from your version.                            }
{                                                         }
{                                                         }
{ The project web site is located on:                     }
{   http://zeos.firmos.at  (FORUM)                        }
{   http://zeosbugs.firmos.at (BUGTRACKER)                }
{   svn://zeos.firmos.at/zeos/trunk (SVN Repository)      }
{                                                         }
{   http://www.sourceforge.net/projects/zeoslib.          }
{   http://www.zeoslib.sourceforge.net                    }
{                                                         }
{                                                         }
{                                                         }
{                                 Zeos Development Group. }
{********************************************************@}

unit ZTestDbcMetadata;

interface
{$I ZDbc.inc}
uses
  Types, Classes, {$IFDEF FPC}testregistry{$ELSE}TestFramework{$ENDIF}, SysUtils,
  ZDbcIntfs, ZSqlTestCase, ZCompatibility;

type
  {** Implements a test case for. }

  { TZGenericTestDbcMetadata }

  TZGenericTestDbcMetadata = class(TZAbstractDbcSQLTestCase)
  private
    MD: IZDatabaseMetadata;
    Catalog, Schema: string;
    ResultSet: IZResultSet;
    TableTypes: TStringDynArray;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure TestMetadataIdentifierQuoting;
    procedure TestMetadataGetCatalogs;
    procedure TestMetadataGetSchemas;
    procedure TestMetadataGetTableTypes;
    procedure TestMetadataGetTables;
    procedure TestMetadataGetColumns;
    procedure TestMetadataGetTablePrivileges;
    procedure TestMetadataGetColumnPrivileges;
    procedure TestMetadataGetBestRowIdentifier;
    procedure TestMetadataGetVersionColumns;
    procedure TestMetadataGetPrimaryKeys;
    procedure TestMetadataGetImportedKeys;
    procedure TestMetadataGetExportedKeys;
    procedure TestMetadataGetCrossReference;
    procedure TestMetadataGetIndexInfo;
    procedure TestMetadataGetProcedures;
    procedure TestMetadataGetProcedureColumns;
    procedure TestMetadataGetTypeInfo;
    procedure TestMetadataGetUDTs;
  end;

implementation

uses ZSysUtils, ZTestConsts, ZDbcMetadata;

{ TZGenericTestDbcMetadata }

{**
   Create objects and allocate memory for variables
}
procedure TZGenericTestDbcMetadata.SetUp;
begin
  inherited SetUp;
  CheckNotNull(Connection);
  MD := Connection.GetMetadata;
  CheckNotNull(MD);

  SetLength(TableTypes, 1);
  TableTypes[0] := 'TABLE';

  ResultSet := MD.GetTables('', '', 'people', TableTypes);
  CheckEquals(ResultSet.First, True, 'No people table');
  Catalog := ResultSet.GetStringByName('TABLE_CAT');
  Schema := ResultSet.GetStringByName('TABLE_SCHEM');
end;

{**
   Destroy objects and free allocated memory for variables
}
procedure TZGenericTestDbcMetadata.TearDown;
begin
  ResultSet := nil;
  MD := nil;
  inherited TearDown;
end;

procedure TZGenericTestDbcMetadata.TestMetadataIdentifierQuoting;
begin
  Check(MD.GetIdentifierConvertor.Quote('99')=MD.GetDatabaseInfo.GetIdentifierQuoteString[1]+'99'+MD.GetDatabaseInfo.GetIdentifierQuoteString[length(MD.GetDatabaseInfo.GetIdentifierQuoteString)]);
  Check(MD.GetIdentifierConvertor.Quote('9A')=MD.GetDatabaseInfo.GetIdentifierQuoteString[1]+'9A'+MD.GetDatabaseInfo.GetIdentifierQuoteString[length(MD.GetDatabaseInfo.GetIdentifierQuoteString)]);
  Check(MD.GetIdentifierConvertor.Quote('A9 A')=MD.GetDatabaseInfo.GetIdentifierQuoteString[1]+'A9 A'+MD.GetDatabaseInfo.GetIdentifierQuoteString[length(MD.GetDatabaseInfo.GetIdentifierQuoteString)]);
  if Not (StartsWith(Protocol, 'postgres') or StartsWith(Protocol, 'FreeTDS')
     or ( Protocol = 'ado' ) or ( Protocol = 'mssql' )) then
    Check(MD.GetIdentifierConvertor.Quote('A9A')='A9A');
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetTableTypes;
begin
  Resultset := MD.GetTableTypes;
  CheckNotNull(ResultSet, 'The resultset is nil');
  PrintResultset(Resultset, False, 'GetTableTypes');
  CheckEquals(TableTypeColumnTableTypeIndex, Resultset.FindColumn('TABLE_TYPE'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetCatalogs;
begin
  Resultset := MD.GetCatalogs;
  CheckNotNull(ResultSet, 'The resultset is nil');
  PrintResultset(Resultset, False, 'GetCatalogs');
  CheckEquals(CatalogNameIndex, Resultset.FindColumn('TABLE_CAT'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetSchemas;
begin
  Resultset := MD.GetSchemas;
  CheckNotNull(ResultSet, 'The resultset is nil');
  PrintResultset(Resultset, False, 'GetSchemas');
  CheckEquals(SchemaColumnsTableSchemaIndex, Resultset.FindColumn('TABLE_SCHEM'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetTables;
const
  Tables: array[0..8] of string = ('people', 'blob_values', 'cargo', 'date_values', 'department', 'equipment', 'equipment2', 'number_values', 'string_values');
var
  I: Integer;
begin
  ResultSet := MD.GetTables(Catalog, Schema, '%', TableTypes);
  CheckNotNull(ResultSet);
  PrintResultSet(Resultset, False, 'GetTables');

  for I := Low(Tables) to High(Tables) do
  begin
    ResultSet := MD.GetTables(Catalog, Schema, Tables[I], TableTypes);
    CheckNotNull(ResultSet, 'The resultset is nil');
    CheckEquals(ResultSet.First, True, 'No ' + Tables[I] + ' table');
    CheckEquals(Catalog, Resultset.GetStringByName('TABLE_CAT'));
    CheckEquals(Schema, Resultset.GetStringByName('TABLE_SCHEM'));
    CheckEquals(UpperCase(Tables[I]), UpperCase(Resultset.GetStringByName('TABLE_NAME')));
    CheckEquals(UpperCase('table'), UpperCase(Resultset.GetStringByName('TABLE_TYPE')));
    CheckEquals('', Resultset.GetStringByName('REMARKS'));
  end;
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetColumns;
var
  Index: Integer;
  procedure CheckColumns(Catalog, Schema, TableName, ColumnName: string;
  DataType: SmallInt; TypeName: string; ColumnSize, BufferLength, DecimalDigits,
  Radix, Nullable: Integer; Remarks, ColumnDef: string; SqlDataType,
  SqlDateTimeSub, CharOctetLength, OrdinalPosition: Integer; IsNullable: string);
  begin
    CheckEquals(ResultSet.Next, True, 'The column is missing: ' + ColumnName);
    CheckEquals(Catalog, ResultSet.GetStringByName('TABLE_CAT'));
    CheckEquals(Schema, ResultSet.GetStringByName('TABLE_SCHEM'));
    CheckEquals(UpperCase(TableName), UpperCase(ResultSet.GetStringByName('TABLE_NAME')));
    CheckEquals(UpperCase(ColumnName), UpperCase(ResultSet.GetStringByName('COLUMN_NAME')));
//    CheckEquals(DataType, ResultSet.GetSmallByName('DATA_TYPE'));
//    CheckEquals(TypeName, ResultSet.GetStringByName('TYPE_NAME'));
//    CheckEquals(ColumnSize, ResultSet.GetIntByName('COLUMN_SIZE'));
//    CheckEquals(BufferLength, ResultSet.GetIntByName('BUFFER_LENGTH'));
//    CheckEquals(DecimalDigits, ResultSet.GetIntByName('DECIMAL_DIGITS'));
//    CheckEquals(Radix, ResultSet.GetIntByName('NUM_PREC_RADIX'));
    CheckEquals(Nullable, ResultSet.GetIntByName('NULLABLE'));
//    CheckEquals(UpperCase(Remarks), UpperCase(ResultSet.GetStringByName('REMARKS')));
//    CheckEquals(UpperCase(ColumnDef), UpperCase(ResultSet.GetStringByName('COLUMN_DEF')));
//    CheckEquals(SqlDataType, ResultSet.GetIntByName('SQL_DATA_TYPE'));
//    CheckEquals(SqlDateTimeSub, ResultSet.GetIntByName('SQL_DATETIME_SUB'));
//    CheckEquals(CharOctetLength, ResultSet.GetIntByName('CHAR_OCTET_LENGTH'));
    CheckEquals(OrdinalPosition, ResultSet.GetIntByName('ORDINAL_POSITION'));
    CheckEquals(UpperCase(IsNullable), UpperCase(ResultSet.GetStringByName('IS_NULLABLE')));
    Inc(Index);
  end;
begin
  Index := 1;
  ResultSet := MD.GetColumns(Catalog, Schema, 'people', '');
  CheckNotNull(ResultSet);
  PrintResultSet(ResultSet, False);

  CheckColumns(Catalog, Schema, 'people', 'p_id', 5, '', 2, 2, 0, 10, 0, '', '', 5, 0, 0, Index, 'no');
  CheckColumns(Catalog, Schema, 'people', 'p_dep_id', 5, '', 2, 2, 0, 10, 1, '', '', 5, 0, 0, Index, 'yes');
  CheckColumns(Catalog, Schema, 'people', 'p_name', 12, '', 40, 40, 0, 0, 1, '', '', 12, 0, 40, Index, 'yes');
  CheckColumns(Catalog, Schema, 'people', 'p_begin_work', 11, '', 16, 16, 0, 0, 1, '', '', 9, 3, 0, Index, 'yes');
  CheckColumns(Catalog, Schema, 'people', 'p_end_work', 11, '', 16, 16, 0, 0, 1, '', '', 9, 3, 0, Index, 'yes');
  CheckColumns(Catalog, Schema, 'people', 'p_picture', -4, '', 2147483647, 2147483647, 0, 0, 1, '', '', -4, 0, 2147483647, Index, 'yes');
  CheckColumns(Catalog, Schema, 'people', 'p_resume', -1, '', 2147483647, 2147483647, 0, 0, 1, '', '', -1, 0, 2147483647, Index, 'yes');
  CheckColumns(Catalog, Schema, 'people', 'p_redundant', -6, '', 1, 1, 0, 10, 1, '', '', -6, 0, 0, Index, 'yes');
  Check(not Resultset.Next, 'There should not be more columns');
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetTablePrivileges;
begin
  ResultSet := MD.GetTablePrivileges(Catalog, Schema, 'people');
  PrintResultSet(ResultSet, False);
  while ResultSet.Next do
  begin
    CheckEquals(Catalog, ResultSet.GetStringByName('TABLE_CAT'));
    CheckEquals(Schema, ResultSet.GetStringByName('TABLE_SCHEM'));
    CheckEquals('PEOPLE', UpperCase(ResultSet.GetStringByName('TABLE_NAME')));
    CheckEquals(TablePrivGrantorIndex, ResultSet.FindColumn('GRANTOR'));
    CheckEquals(TablePrivGranteeIndex, ResultSet.FindColumn('GRANTEE'));
    CheckEquals(TablePrivPrivilegeIndex, ResultSet.FindColumn('PRIVILEGE'));
    CheckEquals(TablePrivIsGrantableIndex, ResultSet.FindColumn('IS_GRANTABLE'));
  end;
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetColumnPrivileges;
begin
  ResultSet := MD.GetColumnPrivileges(Catalog, Schema, 'people', '');
  PrintResultSet(ResultSet, False);
  while ResultSet.Next do
  begin
    CheckEquals(Catalog, Resultset.GetStringByName('TABLE_CAT'));
    CheckEquals(Schema, Resultset.GetStringByName('TABLE_SCHEM'));
    CheckEquals('PEOPLE', UpperCase(Resultset.GetStringByName('TABLE_NAME')));
    CheckEquals(ColumnNameIndex, Resultset.FindColumn('COLUMN_NAME'));
    CheckEquals(TableColPrivGrantorIndex, Resultset.FindColumn('GRANTOR'));
    CheckEquals(TableColPrivGranteeIndex, Resultset.FindColumn('GRANTEE'));
    CheckEquals(TableColPrivPrivilegeIndex, Resultset.FindColumn('PRIVILEGE'));
    CheckEquals(TableColPrivIsGrantableIndex, Resultset.FindColumn('IS_GRANTABLE'));
  end;
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetBestRowIdentifier;
begin
  ResultSet := MD.GetBestRowIdentifier(Catalog, Schema, 'people', 0, True);
  PrintResultSet(ResultSet, False);
  CheckEquals(True, ResultSet.Next, 'There should be 1 bestRow Identifier in the people table');
  CheckEquals(BestRowIdentScopeIndex, Resultset.FindColumn('SCOPE'));
  CheckEquals(UpperCase('p_id'), UpperCase(Resultset.GetStringByName('COLUMN_NAME')));
  CheckEquals(BestRowIdentDataTypeIndex, Resultset.FindColumn('DATA_TYPE'));
  CheckEquals(BestRowIdentTypeNameIndex, Resultset.FindColumn('TYPE_NAME'));
  CheckEquals(BestRowIdentColSizeIndex, Resultset.FindColumn('COLUMN_SIZE'));
  CheckEquals(BestRowIdentBufLengthIndex, Resultset.FindColumn('BUFFER_LENGTH'));
  CheckEquals(BestRowIdentDecimalDigitsIndex, Resultset.FindColumn('DECIMAL_DIGITS'));
  CheckEquals(BestRowIdentPseudoColumnIndex, Resultset.FindColumn('PSEUDO_COLUMN'));
  CheckEquals(False, ResultSet.Next,
    'There should not be more than 1 bestRow Identifier in the people table');
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetVersionColumns;
begin
  ResultSet := MD.GetVersionColumns(Catalog, Schema, 'people');
  PrintResultSet(ResultSet, False);
  CheckEquals(TableColVerScopeIndex, Resultset.FindColumn('SCOPE'));
  CheckEquals(TableColVerColNameIndex, Resultset.FindColumn('COLUMN_NAME'));
  CheckEquals(TableColVerDataTypeIndex, Resultset.FindColumn('DATA_TYPE'));
  CheckEquals(TableColVerTypeNameIndex, Resultset.FindColumn('TYPE_NAME'));
  CheckEquals(TableColVerColSizeIndex, Resultset.FindColumn('COLUMN_SIZE'));
  CheckEquals(TableColVerBufLengthIndex, Resultset.FindColumn('BUFFER_LENGTH'));
  CheckEquals(TableColVerDecimalDigitsIndex, Resultset.FindColumn('DECIMAL_DIGITS'));
  CheckEquals(TableColVerPseudoColumnIndex, Resultset.FindColumn('PSEUDO_COLUMN'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetPrimaryKeys;
begin
  ResultSet := MD.GetPrimaryKeys(Catalog, Schema, 'people');
  PrintResultSet(ResultSet, False);
  CheckEquals(True, ResultSet.Next, 'There should be primary key in the people table');
  CheckEquals(Catalog, Resultset.GetStringByName('TABLE_CAT'));
  CheckEquals(Schema, Resultset.GetStringByName('TABLE_SCHEM'));
  CheckEquals('PEOPLE', UpperCase(Resultset.GetStringByName('TABLE_NAME')));
  CheckEquals('P_ID', UpperCase(Resultset.GetStringByName('COLUMN_NAME')));
  CheckEquals(1, Resultset.GetSmallByName('KEY_SEQ'));
  CheckEquals(PrimaryKeyPKNameIndex, Resultset.FindColumn('PK_NAME'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetImportedKeys;
begin
  if StartsWith(Protocol, 'sqlite')
    or StartsWith(Protocol, 'mysql') then Exit;

  ResultSet := MD.GetImportedKeys(Catalog, Schema, 'people');
  PrintResultSet(ResultSet, False);
  CheckEquals(True, ResultSet.Next, 'There should be an imported key in the people table');
  CheckEquals(Catalog, Resultset.GetStringByName('PKTABLE_CAT'));
  CheckEquals(Schema, Resultset.GetStringByName('PKTABLE_SCHEM'));
  CheckEquals('DEPARTMENT', UpperCase(Resultset.GetStringByName('PKTABLE_NAME')));
  CheckEquals('DEP_ID', UpperCase(Resultset.GetStringByName('PKCOLUMN_NAME')));
  CheckEquals(Catalog, Resultset.GetStringByName('FKTABLE_CAT'));
  CheckEquals(Schema, Resultset.GetStringByName('FKTABLE_SCHEM'));
  CheckEquals('PEOPLE', UpperCase(Resultset.GetStringByName('FKTABLE_NAME')));
  CheckEquals('P_DEP_ID', UpperCase(Resultset.GetStringByName('FKCOLUMN_NAME')));
  CheckEquals(1, Resultset.GetSmallByName('KEY_SEQ'));
  {had two testdatabases with ADO both did allways return 'NO ACTION' as DELETE/UPDATE_RULE so test will be fixed}
  if not (Protocol = 'ado') then
  begin
    CheckEquals(1, Resultset.GetSmallByName('UPDATE_RULE'));
    CheckEquals(1, Resultset.GetSmallByName('DELETE_RULE'));
  end;
  CheckEquals(ImportedKeyColFKNameIndex, Resultset.FindColumn('FK_NAME'));
  CheckEquals(ImportedKeyColPKNameIndex, Resultset.FindColumn('PK_NAME'));
  CheckEquals(ImportedKeyColDeferrabilityIndex, Resultset.FindColumn('DEFERRABILITY'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetExportedKeys;

  procedure CheckExportedKey(PKTable, PKColumn, FKTable, FKColumn: string;
    KeySeq, UpdateRule, DeleteRule: Integer);
  begin
    CheckEquals(Catalog, Resultset.GetStringByName('PKTABLE_CAT'));
    CheckEquals(Schema, Resultset.GetStringByName('PKTABLE_SCHEM'));
    CheckEquals(PKTable, UpperCase(Resultset.GetStringByName('PKTABLE_NAME')));
    CheckEquals(PKColumn, UpperCase(Resultset.GetStringByName('PKCOLUMN_NAME')));
    CheckEquals(Catalog, Resultset.GetStringByName('FKTABLE_CAT'));
    CheckEquals(Schema, Resultset.GetStringByName('FKTABLE_SCHEM'));
    CheckEquals(FKTable, UpperCase(Resultset.GetStringByName('FKTABLE_NAME')));
    CheckEquals(FKColumn, UpperCase(Resultset.GetStringByName('FKCOLUMN_NAME')));
    CheckEquals(KeySeq, Resultset.GetSmallByName('KEY_SEQ'));
    {had two testdatabases with ADO both did allways return 'NO ACTION' as DELETE/UPDATE_RULE so test will be fixed}
    if not (Protocol = 'ado') then
    begin
      CheckEquals(UpdateRule, Resultset.GetSmallByName('UPDATE_RULE'));
      CheckEquals(DeleteRule, Resultset.GetSmallByName('DELETE_RULE'));
    end;
    CheckEquals(ExportedKeyColFKNameIndex, Resultset.FindColumn('FK_NAME'));
    CheckEquals(ExportedKeyColPKNameIndex, Resultset.FindColumn('PK_NAME'));
    CheckEquals(ExportedKeyColDeferrabilityIndex, Resultset.FindColumn('DEFERRABILITY'));
  end;

begin
  if StartsWith(Protocol, 'sqlite')
    or StartsWith(Protocol, 'mysql') then Exit;

  ResultSet := MD.GetExportedKeys(Catalog, Schema, 'department');
  PrintResultSet(ResultSet, False);
  CheckEquals(True, ResultSet.Next, 'There should be more imported key in the department table');
  CheckExportedKey('DEPARTMENT', 'DEP_ID', 'CARGO', 'C_DEP_ID', 1, 1, 1);
  CheckEquals(True, ResultSet.Next, 'There should be more imported key in the department table');
  CheckExportedKey('DEPARTMENT', 'DEP_ID', 'EQUIPMENT2', 'DEP_ID', 1, 1, 1);
  CheckEquals(True, ResultSet.Next, 'There should be more imported key in the department table');
  CheckExportedKey('DEPARTMENT', 'DEP_ID', 'PEOPLE', 'P_DEP_ID', 1, 1, 1);
  CheckEquals(False, ResultSet.Next, 'There should not be more imported key in the department table');
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetCrossReference;
begin
  if StartsWith(Protocol, 'sqlite')
    or StartsWith(Protocol, 'mysql') then Exit;

  ResultSet := MD.GetCrossReference(Catalog, Schema, 'department', Catalog, Schema, 'people');
  PrintResultSet(ResultSet, False);
  CheckEquals(True, ResultSet.Next, 'There should be a cross reference between people and department table');
  CheckEquals(Catalog, Resultset.GetStringByName('PKTABLE_CAT'));
  CheckEquals(Schema, Resultset.GetStringByName('PKTABLE_SCHEM'));
  CheckEquals('DEPARTMENT', UpperCase(Resultset.GetStringByName('PKTABLE_NAME')));
  CheckEquals('DEP_ID', UpperCase(Resultset.GetStringByName('PKCOLUMN_NAME')));
  CheckEquals(Catalog, Resultset.GetStringByName('FKTABLE_CAT'));
  CheckEquals(Schema, Resultset.GetStringByName('FKTABLE_SCHEM'));
  CheckEquals('PEOPLE', UpperCase(Resultset.GetStringByName('FKTABLE_NAME')));
  CheckEquals('P_DEP_ID', UpperCase(Resultset.GetStringByName('FKCOLUMN_NAME')));
  CheckEquals(1, Resultset.GetSmallByName('KEY_SEQ'));
  {had two testdatabases with ADO both did allways return 'NO ACTION' as DELETE/UPDATE_RULE so test will be fixed}
  if not (Protocol = 'ado') then
  begin
    CheckEquals(1, Resultset.GetSmallByName('UPDATE_RULE'));
    CheckEquals(1, Resultset.GetSmallByName('DELETE_RULE'));
  end;
  CheckEquals(CrossRefKeyColFKNameIndex, Resultset.FindColumn('FK_NAME'));
  CheckEquals(CrossRefKeyColPKNameIndex, Resultset.FindColumn('PK_NAME'));
  CheckEquals(CrossRefKeyColDeferrabilityIndex, Resultset.FindColumn('DEFERRABILITY'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetIndexInfo;
begin
  ResultSet := MD.GetIndexInfo(Catalog, Schema, 'people', False, False);
  PrintResultSet(ResultSet, False);
  CheckEquals(True, ResultSet.Next, 'There should be an index on the people table');
  CheckEquals(Catalog, Resultset.GetStringByName('TABLE_CAT'));
  CheckEquals(Schema, Resultset.GetStringByName('TABLE_SCHEM'));
  CheckEquals('PEOPLE', UpperCase(Resultset.GetStringByName('TABLE_NAME')));
  CheckEquals(IndexInfoColNonUniqueIndex, Resultset.FindColumn('NON_UNIQUE'));
  CheckEquals(IndexInfoColIndexQualifierIndex, Resultset.FindColumn('INDEX_QUALIFIER'));
  CheckEquals(IndexInfoColIndexNameIndex, Resultset.FindColumn('INDEX_NAME'));
  CheckEquals(IndexInfoColTypeIndex, Resultset.FindColumn('TYPE'));
  CheckEquals(IndexInfoColOrdPositionIndex, Resultset.FindColumn('ORDINAL_POSITION'));
  CheckEquals(IndexInfoColColumnNameIndex, Resultset.FindColumn('COLUMN_NAME'));
  CheckEquals(IndexInfoColAscOrDescIndex, Resultset.FindColumn('ASC_OR_DESC'));
  CheckEquals(IndexInfoColCardinalityIndex, Resultset.FindColumn('CARDINALITY'));
  CheckEquals(IndexInfoColPagesIndex, Resultset.FindColumn('PAGES'));
  CheckEquals(IndexInfoColFilterConditionIndex, Resultset.FindColumn('FILTER_CONDITION'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetProcedures;
begin
  ResultSet := MD.GetProcedures(Catalog, Schema, '');
  PrintResultSet(ResultSet, False);
  CheckEquals(CatalogNameIndex, Resultset.FindColumn('PROCEDURE_CAT'));
  CheckEquals(SchemaNameIndex, Resultset.FindColumn('PROCEDURE_SCHEM'));
  CheckEquals(ProcedureNameIndex, Resultset.FindColumn('PROCEDURE_NAME'));
  CheckEquals(ProcedureOverloadIndex, Resultset.FindColumn('PROCEDURE_OVERLOAD'));
  CheckEquals(ProcedureReserverd1Index, Resultset.FindColumn('RESERVED1'));
  CheckEquals(ProcedureReserverd2Index, Resultset.FindColumn('RESERVED2'));
  CheckEquals(ProcedureRemarksIndex, Resultset.FindColumn('REMARKS'));
  CheckEquals(ProcedureTypeIndex, Resultset.FindColumn('PROCEDURE_TYPE'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetProcedureColumns;
begin
  ResultSet := MD.GetProcedureColumns(Catalog, Schema, '', '');
  PrintResultSet(ResultSet, False);
  CheckEquals(CatalogNameIndex, Resultset.FindColumn('PROCEDURE_CAT'));
  CheckEquals(SchemaNameIndex, Resultset.FindColumn('PROCEDURE_SCHEM'));
  CheckEquals(ProcColProcedureNameIndex, Resultset.FindColumn('PROCEDURE_NAME'));
  CheckEquals(ProcColColumnNameIndex, Resultset.FindColumn('COLUMN_NAME'));
  CheckEquals(ProcColColumnTypeIndex, Resultset.FindColumn('COLUMN_TYPE'));
  CheckEquals(ProcColDataTypeIndex, Resultset.FindColumn('DATA_TYPE'));
  CheckEquals(ProcColTypeNameIndex, Resultset.FindColumn('TYPE_NAME'));
  CheckEquals(ProcColPrecisionIndex, Resultset.FindColumn('PRECISION'));
  CheckEquals(ProcColLengthIndex, Resultset.FindColumn('LENGTH'));
  CheckEquals(ProcColScaleIndex, Resultset.FindColumn('SCALE'));
  CheckEquals(ProcColRadixIndex, Resultset.FindColumn('RADIX'));
  CheckEquals(ProcColNullableIndex, Resultset.FindColumn('NULLABLE'));
  CheckEquals(ProcColRemarksIndex, Resultset.FindColumn('REMARKS'));
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetTypeInfo;
begin
  ResultSet := MD.GetTypeInfo;
  PrintResultSet(ResultSet, False);
  ResultSet.Close;
end;

procedure TZGenericTestDbcMetadata.TestMetadataGetUDTs;
begin
  if StartsWith(Protocol, 'postgresql')
    or StartsWith(Protocol, 'sqlite') then Exit;
  ResultSet := MD.GetUDTs(Catalog, Schema, '', nil);
  PrintResultSet(ResultSet, False);
  ResultSet.Close;
end;

initialization
  RegisterTest('dbc',TZGenericTestDbcMetadata.Suite);
end.
