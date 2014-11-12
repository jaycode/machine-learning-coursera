%{
 
Copyright: Jev Kuznetsov 
License: BSD
 
demo of SQLite for portfolio management.
 
%}
 
% test sqlite
clear all;
clc;
mksqlite('open','test.db');
 
tables = mksqlite('show tables');
disp(tables);
 
%% create a new data table 
mksqlite('DROP TABLE tbl_portfolios');
sql = 'CREATE TABLE tbl_portfolios ( id INTEGER PRIMARY KEY AUTOINCREMENT, accountName TEXT, symbol TEXT, position INTEGER)'; 
mksqlite(sql);
 
%% now add some random data 
symbols = {'ABC','DEF','GHI','XYZ','AAA','BBB','CCC','DDD'};
accounts = {'acct1','acct2','acct3'}; 
 
%mksqlite('PRAGMA synchronous=OFF'); % speed tweak, see sqlite doc
mksqlite('BEGIN'); % bundle multiple inserts  into one transaction, speed boost!
tic
for i=1:100
    symbol = symbols{ceil(length(symbols)*rand)}; % pick a random symbol from symbols
    account = accounts{ceil(length(accounts)*rand)}; % same for account
    position = ceil(1000*rand); 
     
    fprintf('adding account: %s symbol:%s position:%i \n', symbol,account,position);
     
    % first, check if symbol is already in portfolio
    res = mksqlite(sprintf('SELECT id FROM tbl_portfolios WHERE accountName="%s" AND symbol="%s"',account,symbol));
    if isempty(res)
      fprintf('Adding symbol \n');
      mksqlite(sprintf('INSERT INTO tbl_portfolios (accountName, symbol, position) VALUES ("%s","%s",%i)',account,symbol,position));
    else
      fprintf('Updating symbol \n');
      mksqlite(sprintf('UPDATE tbl_portfolios SET position=%i WHERE id=%i',position,res.id));
    end
     
end
%mksqlite('PRAGMA synchronous=NORMAL');
mksqlite('END');
 
toc
 
%% now pull the data from database
 
fprintf('\nGetting data from database\n');
 
res = mksqlite('SELECT * FROM tbl_portfolios ORDER BY accountName ASC');
fprintf('Account\tSymbol\tposition\n-----------------------\n');
for i=1:length(res)
  fprintf('%s\t%s\t%i\n', res(i).accountName, res(i).symbol,res(i).position);
end
   
%% try some handy sql stuff
% unique account names
res= mksqlite('SELECT DISTINCT accountName FROM tbl_portfolios') 
% sum of all positions in acct1
res= mksqlite('SELECT SUM(position) as sm FROM tbl_portfolios WHERE accountName="acct1"') 
