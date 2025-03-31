export interface TabData {
  id: string;
  filePath: string;
  fileName: string;
  content: string;
}

export interface HeadingItem {
  level: number;
  text: string;
  position: number;
}

export interface GitFileInfo {
  isGitRepository: boolean;
  repositoryRoot: string;
  currentBranch: string;
  lastCommitHash: string;
  lastCommitAuthor: string;
  lastCommitDate: string;
  lastCommitMessage: string;
  fileStatus: string;
  addedByHash: string;
  addedByAuthor: string;
  addedDate: string;
  addedCommitMessage: string;
}
