<template>
  <div class="project-dashboard">
    <!-- Project Selection -->
    <div v-if="loading" class="loading-placeholder">Loading projects...</div>
    <div v-else-if="error" class="error-message">Error loading projects: {{ error }}</div>
    <div v-else-if="projects.length > 0" class="project-selector">
      <label for="projectSelect">Select a Project:</label>
      <select id="projectSelect" v-model="selectedProjectId">
        <option value="">-- Select a Project --</option>
        <option v-for="project in projects" :key="project.id" :value="project.id">
          {{ project.attributes.name }}
        </option>
      </select>
    </div>
    <div v-else class="info-message">No projects found for this hub.</div>

    <!-- Folder/File Tree -->
    <div v-if="selectedProject" class="project-contents">
      <h3>Contents: {{ selectedProject.attributes.name }}</h3>
      <!-- Selected Item Display -->
      <div class="selected-item-info">
        <strong>Selected:</strong>
        <span v-if="selectedItem">{{ selectedItem.attributes?.name || selectedItem.attributes?.displayName || 'Unknown Item' }} (Type: {{ selectedItem.type }})</span>
        <span v-else>None</span>
        <!-- Removed wrapper div -->
        <button
          v-if="selectedItem"
          @click="submitDownloadJob"
          :disabled="downloading"
          class="download-button"
        >
          {{ downloading ? 'Submitting...' : 'Download Selected' }}
        </button>
      </div>
      <!-- Debug text removed -->
      <!-- Debug text removed -->
      <!-- Button moved back inside .selected-item-info -->

      <!-- Tree View Area -->
      <div v-if="folderLoading" class="loading-placeholder">Loading folders...</div>
      <div v-else-if="folderError" class="error-message">Error loading folders: {{ folderError }}</div>
      <div v-else-if="topFolders.length > 0" class="tree-container">
        <TreeView
          :data="topFolders"
          :access-token="props.accessToken"
          :hub-id="props.hubId"
          :project-id="selectedProjectId"
          :selected-item-id="selectedItem?.id"
          @item-selected="handleItemSelected"
        />
      </div>
      <div v-else class="info-message">No top-level folders found for this project.</div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue';
import axios from 'axios';
import TreeView from './TreeView.vue';

const props = defineProps({
  accessToken: { type: String, required: true },
  hubId: { type: String, required: true }
});

// Project state
const projects = ref([]);
const selectedProjectId = ref('');
const loading = ref(false);
const error = ref(null);

// Folder/Item state
const topFolders = ref([]);
const folderLoading = ref(false);
const folderError = ref(null);
const selectedItem = ref(null); // State for the selected item object - Restored
const downloading = ref(false); // State for download button
const downloadError = ref(null); // State for download errors
const downloadJobId = ref(null); // State for submitted job ID

// Computed property for the selected project object
const selectedProject = computed(() => {
  return projects.value.find(p => p.id === selectedProjectId.value) || null;
});

// Method to handle item selection event from TreeView
const handleItemSelected = (item) => {
  // Logs removed, we know this works if the "Selected:" display updates
  // console.log('>>> handleItemSelected triggered. Item:', item);
  // console.log('Item selected in Dashboard:', item?.attributes?.displayName || item?.id);
  selectedItem.value = item; // Update the selected item state
  // No direct call to submitDownloadJob here - let the button handle it
};

// Fetch projects for the current hub
const fetchProjects = async () => {
  if (!props.accessToken || !props.hubId) return;
  loading.value = true;
  error.value = null;
  projects.value = [];
  selectedProjectId.value = ''; // Reset project selection
  topFolders.value = []; // Reset folders on hub change
  selectedItem.value = null; // Reset selection on hub change
  try {
    const response = await axios.get(`http://localhost:3001/hubs/${props.hubId}/projects`, {
      headers: { Authorization: `Bearer ${props.accessToken}` }
    });
    if (response.status !== 200) throw new Error(`Server responded with status ${response.status}`);
    projects.value = Array.isArray(response.data) ? response.data : [];
  } catch (err) {
    error.value = err.response?.data?.message || err.message || 'Failed to fetch projects';
    console.error('Failed to fetch projects', err);
  } finally {
    loading.value = false;
  }
};

// Fetch top-level folders for the selected project - Restored
const fetchTopFolders = async () => {
  if (!props.accessToken || !props.hubId || !selectedProjectId.value) {
      topFolders.value = []; // Clear folders if no project selected
      selectedItem.value = null; // Clear selection if no project selected
      return;
  }
  folderLoading.value = true;
  folderError.value = null;
  topFolders.value = [];
  selectedItem.value = null; // Reset selection on project change
  try {
    const response = await axios.get(`http://localhost:3001/hubs/${props.hubId}/projects/${selectedProjectId.value}/topFolders`, {
      headers: { Authorization: `Bearer ${props.accessToken}` }
    });
    if (response.status !== 200) throw new Error(`Server responded with status ${response.status}`);
    topFolders.value = Array.isArray(response.data) ? response.data : [];
  } catch (err) {
    folderError.value = err.response?.data?.message || err.message || 'Failed to fetch top folders';
    console.error('Failed to fetch top folders', err);
  } finally {
    folderLoading.value = false;
  }
};

// Watchers
watch(() => props.hubId, fetchProjects, { immediate: true });
watch(selectedProjectId, fetchTopFolders);

// Method to submit the download job
const submitDownloadJob = async () => {
  console.log('Preparing download job...');

  if (!selectedItem.value || !selectedProjectId.value) {
    console.error('No item or project selected for download.');
    downloadError.value = 'No item or project selected.';
    return;
  }

  // Try-catch around environment variable access
  let apiKey;
  try {
    apiKey = import.meta.env.VITE_DOWNLOAD_API_KEY;
  } catch (envError) {
    console.error('Error accessing VITE_DOWNLOAD_API_KEY:', envError);
    // Use a hardcoded key for testing
    apiKey = 'dummy-dev-key';
  }
  
  if (!apiKey) {
    console.error('Download API Key is not configured.');
    downloadError.value = 'API Key is missing. Configure VITE_DOWNLOAD_API_KEY in frontend/.env';
    alert('Download API Key is missing. Please configure it in the frontend/.env file and restart the server.');
    return;
  }

  downloading.value = true;
  downloadError.value = null;
  downloadJobId.value = null;

  // CORS Workaround: Use our backend as a proxy instead of direct API call
  // const url = 'http://localhost:5001/api/v1/download'; // Original direct URL
  const url = 'http://localhost:3001/proxy/download'; // New proxy URL
  
  const headers = {
    'Content-Type': 'application/json',
  };

  const body = {
    project_id: selectedProjectId.value,
    api_key: apiKey, // Send API key in the body instead of header for the proxy
    destination: `./downloads/${selectedProject.value?.attributes?.name || 'project'}`, // Removed item name from destination
  };

  if (selectedItem.value.type === 'folders') {
    body.folder_id = selectedItem.value.id;
  } else if (selectedItem.value.type === 'items' || selectedItem.value.type.startsWith('items:')) {
    body.item_id = selectedItem.value.id;
  } else {
    console.error('Unknown selected item type:', selectedItem.value.type);
    downloadError.value = `Cannot download item of type: ${selectedItem.value.type}`;
    downloading.value = false;
    return;
  }
  
  console.log('Submitting download job:', { url, body });

  try {
    const response = await axios.post(url, body, { headers });
    if (response.status === 202 || response.status === 200) { // Accept both 202 and 200
      downloadJobId.value = response.data.job_id;
      console.log('Download job submitted successfully:', response.data);
      alert(`Download job submitted! Job ID: ${downloadJobId.value}`);
    } else {
      throw new Error(`API responded with status ${response.status}`);
    }
  } catch (err) {
    console.error('Failed to submit download job:', err);
    downloadError.value = err.response?.data?.detail || err.response?.data?.message || err.message || 'Failed to submit download job.';
    alert(`Error submitting download: ${downloadError.value}`);
  } finally {
    downloading.value = false;
  }
};

</script>

<style scoped>
/* Use variables defined in App.vue's global style or replicate values */
:root { /* Define fallback values if global styles aren't inherited reliably */
  --primary-color: #007bff;
  --medium-gray: #dee2e6;
  --light-gray: #f8f9fa;
  --dark-gray: #343a40;
  --text-color: #212529;
  --error-color: #dc3545;
  --border-radius: 0.25rem;
  --input-padding: 0.5rem 0.75rem;
}

.project-dashboard {
  /* Inherits card styling from App.vue if nested directly, otherwise define here */
  /* Assuming it's nested within a card or needs its own container */
   padding: 1rem; /* Add padding if not already in a card */
   margin-top: 1rem; /* Space from hub selector */
}

.project-selector {
  margin-bottom: 1.5rem;
}

label {
 display: block;
 margin-bottom: 0.25rem;
 font-weight: 500;
 color: var(--dark-gray, #343a40);
}

select {
  width: 100%;
  padding: var(--input-padding, 0.5rem 0.75rem);
  border-radius: var(--border-radius, 0.25rem);
  border: 1px solid var(--medium-gray, #dee2e6);
  font-size: 1rem;
  box-sizing: border-box;
  background-color: white; /* Ensure background */
  appearance: none; /* Modern look for select */
  background-image: url("data:image/svg+xml,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3e%3cpath fill='none' stroke='%23343a40' stroke-linecap='round' stroke-linejoin='round' stroke-width='2' d='M2 5l6 6 6-6'/%3e%3c/svg%3e");
  background-repeat: no-repeat;
  background-position: right 0.75rem center;
  background-size: 16px 12px;
}

select:focus {
  border-color: var(--primary-color, #007bff);
  outline: 0;
  box-shadow: 0 0 0 0.2rem rgba(0, 123, 255, 0.25);
}


.project-contents h3 {
  margin-top: 0; /* Remove top margin if it's the first element */
  margin-bottom: 1rem;
  color: var(--dark-gray, #343a40);
  border-bottom: 1px solid var(--medium-gray, #dee2e6);
  padding-bottom: 0.5rem;
  font-size: 1.25rem;
}

.selected-item-info {
  margin-bottom: 1rem;
  padding: 0.75rem 1rem;
  background-color: #e9ecef; /* Slightly different background */
  border-radius: var(--border-radius, 0.25rem);
  font-size: 0.95em;
  color: #495057;
  border: 1px solid #ced4da;
}

.selected-item-info strong {
  margin-right: 0.5em;
}

.download-button {
  margin-left: 1rem;
  padding: 0.4rem 0.8rem;
  background-color: var(--primary-color, #007bff);
  color: white;
  border: none;
  border-radius: var(--border-radius, 0.25rem);
  cursor: pointer;
  font-size: 0.9em;
  transition: background-color 0.2s ease;
  /* Removed pointer-events, position, z-index from previous attempts */
}

.download-button:hover:not(:disabled) {
  background-color: #0056b3; /* Darker shade on hover */
}

.download-button:disabled {
  background-color: var(--medium-gray, #dee2e6);
  cursor: not-allowed;
}

.tree-container {
  margin-top: 1rem;
  padding: 1rem;
  border: 1px solid var(--medium-gray, #dee2e6);
  border-radius: var(--border-radius, 0.25rem);
  background-color: white; /* White background for the tree */
  max-height: 50vh; /* Limit height */
  overflow-y: auto;
}

.loading-placeholder, .info-message, .error-message {
  padding: 1rem;
  text-align: center;
  color: var(--secondary-color, #6c757d);
  background-color: var(--light-gray, #f8f9fa);
  border: 1px dashed var(--medium-gray, #dee2e6);
  border-radius: var(--border-radius, 0.25rem);
  margin-bottom: 1rem;
}

.error-message {
  color: var(--error-color, #dc3545);
  background-color: #f8d7da;
  border-color: #f5c6cb;
}
</style>