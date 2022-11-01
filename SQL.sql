CREATE TABLE `credit` (
    `citizenid` text  NULL,
  `type` text  NOT NULL,
  `account` text  NOT NULL,
  `balance` text  NOT NULL,
  `limit` text NOT NULL,
  `interest` text NOT NULL,
  `paid` text NOT NULL,
  `timer` text NOT NULL
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=latin1;

ALTER TABLE `players` ADD COLUMN `credit_score` VARCHAR(255) NULL DEFAULT '400';
ALTER TABLE `players` ADD COLUMN `credit_level` VARCHAR(255) NULL DEFAULT '2';