package v1

import (
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"

	"github.com/IceWhaleTech/CasaOS/model"
	"github.com/IceWhaleTech/CasaOS/pkg/utils/common_err"
	"github.com/labstack/echo/v4"
)

var safeDockerID = regexp.MustCompile(`^[a-zA-Z0-9_.-]+$`)

func dockerResult(ctx echo.Context, data interface{}, err error) error {
	if err != nil {
		return ctx.JSON(http.StatusInternalServerError, model.Result{Success: common_err.SERVICE_ERROR, Message: err.Error()})
	}
	return ctx.JSON(http.StatusOK, model.Result{Success: common_err.SUCCESS, Message: common_err.GetMsg(common_err.SUCCESS), Data: data})
}

func runDocker(args ...string) ([]byte, error) {
	cmd := exec.Command("docker", args...)
	return cmd.CombinedOutput()
}

func ListDockerContainers(ctx echo.Context) error {
	out, err := runDocker("ps", "-a", "--format", "{{json .}}")
	if err != nil {
		return dockerResult(ctx, nil, fmt.Errorf("docker ps: %s", strings.TrimSpace(string(out))))
	}
	lines := strings.Split(strings.TrimSpace(string(out)), "\n")
	result := make([]map[string]interface{}, 0, len(lines))
	for _, line := range lines {
		if strings.TrimSpace(line) == "" {
			continue
		}
		var item map[string]interface{}
		if json.Unmarshal([]byte(line), &item) == nil {
			result = append(result, item)
		}
	}
	return dockerResult(ctx, result, nil)
}

func DockerContainerAction(ctx echo.Context) error {
	id, action := ctx.Param("id"), strings.ToLower(ctx.Param("action"))
	if !safeDockerID.MatchString(id) {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: "invalid container id"})
	}
	allowed := map[string]bool{"start": true, "stop": true, "restart": true, "pause": true, "unpause": true}
	if !allowed[action] {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: "unsupported action"})
	}
	out, err := runDocker(action, id)
	if err != nil {
		return dockerResult(ctx, nil, fmt.Errorf("docker %s: %s", action, strings.TrimSpace(string(out))))
	}
	return dockerResult(ctx, map[string]string{"container": id, "action": action, "output": strings.TrimSpace(string(out))}, nil)
}

func DockerContainerLogs(ctx echo.Context) error {
	id := ctx.Param("id")
	if !safeDockerID.MatchString(id) {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: "invalid container id"})
	}
	tail := ctx.QueryParam("tail")
	if tail == "" {
		tail = "200"
	}
	out, err := runDocker("logs", "--tail", tail, id)
	if err != nil && len(out) == 0 {
		return dockerResult(ctx, nil, err)
	}
	return dockerResult(ctx, string(out), nil)
}

func DockerContainerStats(ctx echo.Context) error {
	id := ctx.Param("id")
	if !safeDockerID.MatchString(id) {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: "invalid container id"})
	}
	out, err := runDocker("stats", "--no-stream", "--format", "{{json .}}", id)
	if err != nil {
		return dockerResult(ctx, nil, fmt.Errorf("docker stats: %s", strings.TrimSpace(string(out))))
	}
	var item map[string]interface{}
	if json.Unmarshal(out, &item) != nil {
		return dockerResult(ctx, string(out), nil)
	}
	return dockerResult(ctx, item, nil)
}

type ComposeRequest struct {
	Project   string `json:"project"`
	Directory string `json:"directory"`
	Yaml      string `json:"yaml"`
}

func DockerComposeUp(ctx echo.Context) error {
	var req ComposeRequest
	if err := ctx.Bind(&req); err != nil {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: err.Error()})
	}
	if !safeDockerID.MatchString(req.Project) {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: "project must contain only letters, numbers, dot, underscore or hyphen"})
	}
	if req.Directory == "" {
		req.Directory = "/DATA/Apps/" + req.Project
	}
	if !strings.HasPrefix(req.Directory, "/DATA/") && !strings.HasPrefix(req.Directory, "/opt/") {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: "directory must be under /DATA or /opt"})
	}
	if strings.TrimSpace(req.Yaml) == "" {
		return ctx.JSON(http.StatusBadRequest, model.Result{Success: common_err.INVALID_PARAMS, Message: "yaml is required"})
	}
	if err := os.MkdirAll(req.Directory, 0o755); err != nil {
		return dockerResult(ctx, nil, fmt.Errorf("create compose directory: %w", err))
	}
	composePath := filepath.Join(req.Directory, "compose.yaml")
	if err := os.WriteFile(composePath, []byte(req.Yaml), 0o644); err != nil {
		return dockerResult(ctx, nil, fmt.Errorf("write compose file: %w", err))
	}
	cmd := exec.Command("docker", "compose", "-p", req.Project, "up", "-d")
	cmd.Dir = req.Directory
	out, err := cmd.CombinedOutput()
	if err != nil {
		return dockerResult(ctx, nil, fmt.Errorf("compose up: %s", strings.TrimSpace(string(out))))
	}
	return dockerResult(ctx, map[string]string{"project": req.Project, "directory": req.Directory, "output": strings.TrimSpace(string(out))}, nil)
}
