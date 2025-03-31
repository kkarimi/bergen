import { useEffect, useState } from 'react';
import { NativeModules } from 'react-native';
import type { GitFileInfo } from '../types';

const { GitModule } = NativeModules;

// Default empty git info
const defaultGitInfo: GitFileInfo = {
  isGitRepository: false,
  repositoryRoot: '',
  currentBranch: '',
  lastCommitHash: '',
  lastCommitAuthor: '',
  lastCommitDate: '',
  lastCommitMessage: '',
  fileStatus: '',
  addedByHash: '',
  addedByAuthor: '',
  addedDate: '',
  addedCommitMessage: ''
};

export function useGitInfo(filePath?: string | null): {
  gitInfo: GitFileInfo;
  isLoading: boolean;
  error: Error | null;
} {
  const [gitInfo, setGitInfo] = useState<GitFileInfo>(defaultGitInfo);
  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [error, setError] = useState<Error | null>(null);

  useEffect(() => {
    let mounted = true;

    const fetchGitInfo = async () => {
      if (!filePath) {
        setGitInfo(defaultGitInfo);
        return;
      }

      try {
        setIsLoading(true);
        setError(null);

        // First check if the file is in a git repository
        if (GitModule) {
          const gitInfo = await GitModule.getFileGitInfo(filePath);

          if (mounted) {
            setGitInfo(gitInfo);
            setIsLoading(false);
          }
        } else {
          if (mounted) {
            setGitInfo(defaultGitInfo);
            setIsLoading(false);
            setError(new Error('Git module not available'));
          }
        }
      } catch (err) {
        console.error('Error fetching git info:', err);
        if (mounted) {
          setGitInfo(defaultGitInfo);
          setIsLoading(false);
          setError(err instanceof Error ? err : new Error('Unknown error'));
        }
      }
    };

    fetchGitInfo();

    return () => {
      mounted = false;
    };
  }, [filePath]);

  return { gitInfo, isLoading, error };
}
