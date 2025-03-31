import React from 'react';
import {
  ActivityIndicator,
  ScrollView,
  StyleSheet,
  Text,
  View,
  useColorScheme
} from 'react-native';
import type RNFS from 'react-native-fs';
import { useGitInfo } from '../hooks/useGitInfo';
import type { GitFileInfo } from '../types';

interface FileInfoProps {
  file?: RNFS.ReadDirItem | null;
  activeFilePath?: string;
}

const FileInfo = ({ file, activeFilePath }: FileInfoProps) => {
  const isDarkMode = useColorScheme() === 'dark';
  const currentPath = file?.path || activeFilePath;
  const { gitInfo, isLoading, error } = useGitInfo(currentPath);

  if (!file && !activeFilePath) {
    return (
      <View style={[styles.container, { backgroundColor: isDarkMode ? '#1C1C1E' : '#F2F2F7' }]}>
        <Text style={{ color: isDarkMode ? '#8E8E93' : '#8E8E93', textAlign: 'center' }}>
          No file selected
        </Text>
      </View>
    );
  }

  // Format file size to readable format
  const formatFileSize = (bytes?: number) => {
    if (!bytes) return 'Unknown';

    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    let size = bytes;
    let unitIndex = 0;

    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }

    return `${size.toFixed(1)} ${units[unitIndex]}`;
  };

  // Format date to readable format
  const formatDate = (date?: Date) => {
    if (!date) return 'Unknown';
    return date.toLocaleString();
  };

  // Format git date string
  const formatGitDate = (dateStr: string) => {
    if (!dateStr) return 'Unknown';
    return dateStr;
  };

  // Get a human-readable status for the file
  const getFileStatusText = (status: string) => {
    if (!status) return 'Unchanged';

    if (status.startsWith('M')) return 'Modified';
    if (status.startsWith('A')) return 'Added';
    if (status.startsWith('D')) return 'Deleted';
    if (status.startsWith('R')) return 'Renamed';
    if (status.startsWith('C')) return 'Copied';
    if (status.startsWith('U')) return 'Updated but unmerged';
    if (status.startsWith('?')) return 'Untracked';
    if (status.startsWith('!')) return 'Ignored';

    return status;
  };

  return (
    <View style={[styles.container, { backgroundColor: isDarkMode ? '#1C1C1E' : '#F2F2F7' }]}>
      <View style={styles.header}>
        <Text style={[styles.headerText, { color: isDarkMode ? '#FFFFFF' : '#000000' }]}>
          File Info
        </Text>
      </View>

      <ScrollView style={styles.infoContainer}>
        <View style={styles.section}>
          <Text style={[styles.sectionTitle, { color: isDarkMode ? '#FFFFFF' : '#000000' }]}>
            Basic Information
          </Text>

          <InfoItem
            label="Name"
            value={file?.name || activeFilePath?.split('/').pop() || 'Unknown'}
            isDarkMode={isDarkMode}
          />

          <InfoItem label="Size" value={formatFileSize(file?.size)} isDarkMode={isDarkMode} />

          <InfoItem
            label="Path"
            value={file?.path || activeFilePath || 'Unknown'}
            isDarkMode={isDarkMode}
          />

          <InfoItem label="Created" value={formatDate(file?.ctime)} isDarkMode={isDarkMode} />

          <InfoItem label="Modified" value={formatDate(file?.mtime)} isDarkMode={isDarkMode} />

          <InfoItem label="Accessed" value={formatDate(file?.atime)} isDarkMode={isDarkMode} />

          <InfoItem
            label="Type"
            value={file?.isDirectory() ? 'Directory' : 'File'}
            isDarkMode={isDarkMode}
          />
        </View>

        {isLoading ? (
          <View style={styles.loadingContainer}>
            <ActivityIndicator size="small" color={isDarkMode ? '#2C9BF0' : '#007AFF'} />
            <Text style={{ color: isDarkMode ? '#8E8E93' : '#8E8E93', marginTop: 10 }}>
              Loading Git information...
            </Text>
          </View>
        ) : error ? (
          <Text style={{ color: isDarkMode ? '#FF453A' : '#FF3B30', padding: 10 }}>
            Error loading Git info
          </Text>
        ) : gitInfo.isGitRepository ? (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: isDarkMode ? '#FFFFFF' : '#000000' }]}>
              Git Information
            </Text>

            <InfoItem
              label="Repository"
              value={gitInfo.repositoryRoot.split('/').pop() || 'Unknown'}
              isDarkMode={isDarkMode}
            />

            <InfoItem label="Branch" value={gitInfo.currentBranch} isDarkMode={isDarkMode} />

            <InfoItem
              label="Status"
              value={getFileStatusText(gitInfo.fileStatus)}
              isDarkMode={isDarkMode}
            />

            <InfoItem
              label="Last Commit"
              value={gitInfo.lastCommitHash.substring(0, 7)}
              isDarkMode={isDarkMode}
            />

            <InfoItem
              label="Last Author"
              value={gitInfo.lastCommitAuthor}
              isDarkMode={isDarkMode}
            />

            <InfoItem
              label="Last Date"
              value={formatGitDate(gitInfo.lastCommitDate)}
              isDarkMode={isDarkMode}
            />

            <InfoItem
              label="Last Message"
              value={gitInfo.lastCommitMessage}
              isDarkMode={isDarkMode}
            />

            <InfoItem
              label="Added By"
              value={gitInfo.addedByAuthor || 'Unknown'}
              isDarkMode={isDarkMode}
            />

            <InfoItem
              label="Added Date"
              value={formatGitDate(gitInfo.addedDate)}
              isDarkMode={isDarkMode}
            />
          </View>
        ) : (
          <View style={styles.section}>
            <Text style={[styles.sectionTitle, { color: isDarkMode ? '#FFFFFF' : '#000000' }]}>
              Git Information
            </Text>
            <Text style={{ color: isDarkMode ? '#8E8E93' : '#8E8E93', fontStyle: 'italic' }}>
              Not a Git repository
            </Text>
          </View>
        )}
      </ScrollView>
    </View>
  );
};

interface InfoItemProps {
  label: string;
  value: string;
  isDarkMode: boolean;
}

const InfoItem = ({ label, value, isDarkMode }: InfoItemProps) => (
  <View style={styles.infoItem}>
    <Text style={[styles.infoLabel, { color: isDarkMode ? '#8E8E93' : '#8E8E93' }]}>{label}:</Text>
    <Text
      style={[styles.infoValue, { color: isDarkMode ? '#FFFFFF' : '#000000' }]}
      numberOfLines={1}
      ellipsizeMode="middle"
    >
      {value}
    </Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    width: 250,
    borderLeftWidth: 0.5,
    borderLeftColor: '#AAAAAA'
  },
  header: {
    padding: 10,
    borderBottomWidth: 0.5,
    borderBottomColor: '#AAAAAA'
  },
  headerText: {
    fontSize: 14,
    fontWeight: 'bold',
    textAlign: 'center'
  },
  infoContainer: {
    flex: 1,
    padding: 10
  },
  section: {
    marginBottom: 20
  },
  sectionTitle: {
    fontSize: 13,
    fontWeight: 'bold',
    marginBottom: 10,
    borderBottomWidth: 0.5,
    borderBottomColor: '#AAAAAA',
    paddingBottom: 4
  },
  infoItem: {
    marginBottom: 12
  },
  infoLabel: {
    fontSize: 12,
    fontWeight: '600',
    marginBottom: 4
  },
  infoValue: {
    fontSize: 12
  },
  loadingContainer: {
    padding: 20,
    alignItems: 'center'
  }
});

export default FileInfo;
