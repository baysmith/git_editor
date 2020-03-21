#![allow(dead_code, unused_imports, unused_macros)]
use chrono::prelude::*;
use clipboard::{ClipboardContext, ClipboardProvider};
use env_logger::fmt::Color;
use image::{GenericImageView, Pixel};
use imgui::*;
use imgui_wgpu::Renderer;
use imgui_winit_support::{HiDpiMode, WinitPlatform};
use log::{error, info};
use preferences::{AppInfo, Preferences};
use raw_window_handle::{HasRawWindowHandle, RawWindowHandle};
use serde::{Deserialize, Serialize};
use std::io::BufRead;
use std::io::Write;
use winapi::um::winuser::{
    GetWindowLongW, SetWindowLongW, ShowWindow, GWL_EXSTYLE, SW_HIDE, SW_SHOW, WS_EX_APPWINDOW,
    WS_EX_TOOLWINDOW, WS_VISIBLE,
};
use winit::{
    event::{ElementState, Event, MouseButton, VirtualKeyCode, WindowEvent},
    event_loop::EventLoop,
    platform::desktop::EventLoopExtDesktop,
};

const APP_INFO: AppInfo = AppInfo {
    name: "git-editor",
    author: "baysmith",
};

#[derive(Serialize, Deserialize, Debug, Default)]
struct SaveState {
    window_position: (i32, i32),
}

impl SaveState {
    fn new() -> Self {
        SaveState {
            window_position: (110, 110),
        }
    }
}

macro_rules! wgpu_color {
    ($f:ident) => {
        wgpu::Color {
            r: $f.0,
            g: $f.1,
            b: $f.2,
            a: $f.3,
        }
    };
}

macro_rules! im_color {
    ($r:expr, $g:expr, $b:expr, $a:expr) => {
        [
            $r as f32 / 255.0,
            $g as f32 / 255.0,
            $b as f32 / 255.0,
            $a as f32 / 255.0,
        ]
    };
    ($r:expr, $g:expr, $b:expr) => {
        [
            $r as f32 / 255.0,
            $g as f32 / 255.0,
            $b as f32 / 255.0,
            1.0f32,
        ]
    };
}

macro_rules! v2 {
    ($x:expr, $y:expr) => {
        ImVec2 { x: $x, y: $y }
    };
}

pub struct ClipboardSupport(ClipboardContext);

impl ClipboardBackend for ClipboardSupport {
    fn get(&mut self) -> Option<ImString> {
        self.0.get_contents().ok().map(|text| text.into())
    }
    fn set(&mut self, text: &ImStr) {
        let _ = self.0.set_contents(text.to_str().to_owned());
    }
}

fn is_mouse_hovering_window(ui: &imgui::Ui) -> bool {
    ui.is_window_hovered_with_flags(
        imgui::WindowHoveredFlags::ALLOW_WHEN_BLOCKED_BY_POPUP
            | imgui::WindowHoveredFlags::ALLOW_WHEN_BLOCKED_BY_ACTIVE_ITEM,
    )
}

fn imgui_app(mut data: Box<dyn AppData>) {
    let title = "Git Editor";
    let background_color = (0.0, 0.0, 0.0, 1.0);

    let image = image::load_from_memory(include_bytes!("../resources/icon.png"))
        .expect("Unable to load icon");
    let (icon_width, icon_height) = image.dimensions();
    let mut icon_rgba = Vec::with_capacity((icon_width * icon_height) as usize * 4);
    for (_, _, pixel) in image.pixels() {
        icon_rgba.extend_from_slice(&pixel.to_rgba().0);
    }
    let icon = winit::window::Icon::from_rgba(icon_rgba, icon_width, icon_height)
        .expect("Failed to open icon");

    let mut event_loop = EventLoop::new();
    let builder = winit::window::WindowBuilder::new()
        .with_title(title.to_owned())
        .with_inner_size(data.default_window_size())
        .with_window_icon(Some(icon))
        .with_resizable(true)
        .with_visible(false);
    let window = builder.build(&event_loop).unwrap();
    let mut size = window.inner_size();
    let surface = wgpu::Surface::create(&window);

    let (device, mut queue) = wgpu::Adapter::request(&wgpu::RequestAdapterOptions {
        power_preference: wgpu::PowerPreference::LowPower,
        backends: wgpu::BackendBit::PRIMARY,
    })
    .unwrap()
    .request_device(&wgpu::DeviceDescriptor {
        extensions: wgpu::Extensions {
            anisotropic_filtering: false,
        },
        limits: wgpu::Limits::default(),
    });

    // Set up swap chain
    let mut sc_desc = wgpu::SwapChainDescriptor {
        usage: wgpu::TextureUsage::OUTPUT_ATTACHMENT,
        format: wgpu::TextureFormat::Bgra8Unorm,
        width: size.width as u32,
        height: size.height as u32,
        present_mode: wgpu::PresentMode::NoVsync,
    };

    let mut imgui = Context::create();
    imgui.set_ini_filename(None);
    let font = imgui.fonts().add_font(&[FontSource::TtfData {
        data: include_bytes!("../resources/JetBrainsMono-Regular.ttf"),
        size_pixels: 15.0,
        config: None,
    }]);

    let clipboard_support =
        ClipboardSupport(ClipboardContext::new().expect("Unable to create ClipboardContext"));
    imgui.set_clipboard_backend(Box::new(clipboard_support));

    let mut platform = WinitPlatform::init(&mut imgui);
    platform.attach_window(imgui.io_mut(), &window, HiDpiMode::Rounded);

    let mut renderer = Renderer::new_static(
        &mut imgui,
        &device,
        &mut queue,
        sc_desc.format,
        Some(wgpu_color! { background_color }),
    );

    let mut last_frame_time = std::time::Instant::now();

    // let load_result = SaveState::load(&APP_INFO, "save_state");
    // let save_state = if load_result.is_ok() {
    //     load_result.unwrap()
    // } else {
    //     SaveState::new()
    // };
    let window_position: (i32, i32) = (
        (1920 - size.width as i32) / 2,
        (1080 - size.height as i32) / 2,
    );
    // let window_position: (i32, i32) = save_state.window_position;
    let mut first = true;

    let mut swap_chain = device.create_swap_chain(&surface, &sc_desc);

    data.init(&imgui);

    let frame_rate_ms = 17.0;
    let mut quit = false;
    while !quit {
        event_loop.run_return(|event, _window_target, control_flow| {
            if let Event::DeviceEvent { .. } = event {
                return;
            }
            let mut redraw = false;
            if first {
                window.set_outer_position(winit::dpi::PhysicalPosition::new(
                    window_position.0,
                    window_position.1,
                ));
                window.set_visible(true);
                first = false;
            }
            platform.handle_event(imgui.io_mut(), &window, &event);

            // Limit event rate when no events are occuring
            *control_flow = winit::event_loop::ControlFlow::WaitUntil(
                std::time::Instant::now()
                    .checked_add(std::time::Duration::from_millis(frame_rate_ms as u64))
                    .unwrap(),
            );

            match event {
                Event::WindowEvent {
                    event: WindowEvent::Resized(_),
                    ..
                } => {
                    size = window.inner_size();

                    sc_desc = wgpu::SwapChainDescriptor {
                        usage: wgpu::TextureUsage::OUTPUT_ATTACHMENT,
                        format: wgpu::TextureFormat::Bgra8Unorm,
                        width: size.width as u32,
                        height: size.height as u32,
                        present_mode: wgpu::PresentMode::NoVsync,
                    };

                    swap_chain = device.create_swap_chain(&surface, &sc_desc);
                    redraw = true;
                }
                Event::WindowEvent {
                    event: WindowEvent::CloseRequested,
                    ..
                } => {
                    quit = true;
                }
                Event::MainEventsCleared => {
                    *control_flow = winit::event_loop::ControlFlow::Exit;
                }
                _ => (),
            }

            let io = imgui.io_mut();
            io.config_flags
                .set(imgui::ConfigFlags::NO_MOUSE_CURSOR_CHANGE, true);
            let now = io.update_delta_time(last_frame_time);
            // Limit frame rate
            if redraw || io.delta_time > frame_rate_ms / 1000.0 {
                last_frame_time = now;

                let frame = swap_chain.get_next_texture();
                platform
                    .prepare_frame(io, &window)
                    .expect("Failed to start frame");
                let mut ui = imgui.frame();

                let font_token = ui.push_font(font);

                if data.frame(&mut ui, size) {
                    quit = true;
                    *control_flow = winit::event_loop::ControlFlow::Exit;
                }

                font_token.pop(&ui);

                let mut encoder: wgpu::CommandEncoder =
                    device.create_command_encoder(&wgpu::CommandEncoderDescriptor { todo: 0 });

                platform.prepare_render(&ui, &window);
                renderer
                    .render(ui.render(), &device, &mut encoder, &frame.view)
                    .expect("Rendering failed");

                queue.submit(&[encoder.finish()]);
            } else {
                std::thread::sleep(std::time::Duration::from_millis(
                    ((frame_rate_ms - (io.delta_time * 1000.0)) * 0.8) as u64,
                ));
            }
        });
    }
    data.exit();
}

trait AppData {
    fn default_window_size(&mut self) -> winit::dpi::PhysicalSize<u32>;
    fn init(&mut self, imgui: &imgui::Context);
    fn frame(&mut self, ui: &mut Ui, size: winit::dpi::PhysicalSize<u32>) -> bool;
    fn exit(&mut self);
}

struct MessageData {
    button_padding: [f32; 2],
    line_count: u32,
    comment: ImString,
    message_file: String,
}

impl MessageData {
    fn new(message_file: String) -> Self {
        let file = std::fs::File::open(&message_file).expect("Unable to open commit message file");
        let mut lines = std::io::BufReader::new(file).lines();
        // Count lines to use when calculating an approximate window height
        let mut line_count = 5;
        let mut comment = String::new();
        // If first line is empty, add an extra line before commit comment instructions.
        if let Some(Ok(line)) = lines.next() {
            if line.is_empty() {
                line_count += 2;
                comment.push_str("\n\n");
            } else {
                line_count += 1;
                comment.push_str(line.as_str());
                comment.push_str("\n");
            }
        }
        for line in lines {
            if let Ok(line) = line {
                line_count += 1;
                comment.push_str(line.as_str());
                comment.push_str("\n");
            }
        }

        let mut data = MessageData {
            button_padding: [0.0, 0.0],
            line_count,
            comment: ImString::with_capacity(comment.len() + 2048),
            message_file,
        };
        // let message =
        //     std::fs::read_to_string(&data.message_file).expect("Unable to read commit message file");
        data.comment.push_str(comment.as_str());
        data
    }
}

impl AppData for MessageData {
    fn default_window_size(&mut self) -> winit::dpi::PhysicalSize<u32> {
        winit::dpi::PhysicalSize::new(700, std::cmp::min(self.line_count * 20, 980))
    }
    fn init(&mut self, imgui: &imgui::Context) {
        self.button_padding = imgui.style().frame_padding;
    }
    fn frame(&mut self, ui: &mut Ui, size: winit::dpi::PhysicalSize<u32>) -> bool {
        let mut quit = false;
        Window::new(im_str!("App"))
            .size(
                [size.width as f32 - 4.0, size.height as f32 - 4.0],
                Condition::Always,
            )
            .position([0.0, 0.0], Condition::FirstUseEver)
            .flags(WindowFlags::NO_TITLE_BAR | WindowFlags::NO_MOVE | WindowFlags::NO_RESIZE)
            .build(&ui, || {
                if ui.is_key_released(VirtualKeyCode::W as u32)
                    && (ui.is_key_down(VirtualKeyCode::LControl as u32)
                        || ui.is_key_down(VirtualKeyCode::RControl as u32))
                {
                    quit = true;
                    return;
                }

                let offset = ui.cursor_screen_pos();

                let abort_text = im_str!("Abort");
                let button_text_size = ui.calc_text_size(&abort_text, true, -1.0);
                let mut abort_pos = ui.window_content_region_max();
                let button_size = [
                    button_text_size[0] + 2.0 * self.button_padding[0],
                    button_text_size[1] + 2.0 * self.button_padding[1],
                ];
                abort_pos[0] -= button_size[0];
                abort_pos[1] -= button_size[1];
                ui.set_cursor_screen_pos(abort_pos);
                if ui.button(abort_text, button_size) {
                    std::process::exit(1);
                }

                if ui.is_window_focused() && !ui.is_any_item_active() {
                    ui.set_keyboard_focus_here(imgui::FocusedWidget::Next);
                }
                ui.set_cursor_screen_pos(offset);
                let mut input_size = ui.window_size();
                input_size[0] -= 2.0 * offset[0];
                input_size[1] -= 2.0 * offset[1] + button_size[1];
                ui.input_text_multiline(im_str!("##commit-comment"), &mut self.comment, input_size)
                    .build();
            });
        quit
    }
    fn exit(&mut self) {
        std::fs::write(&self.message_file, &self.comment.to_str())
            .expect("Unable to write commit message file");
    }
}

#[derive(Debug)]
struct RebaseAction {
    operation: String,
    sha: String,
    message: String,
}

impl RebaseAction {
    fn new(line: String) -> Self {
        let mut action_data: Vec<String> = line.splitn(3, ' ').map(|s| s.to_string()).collect();
        RebaseAction {
            message: action_data.pop().expect("Expected rebase commit message"),
            sha: action_data.pop().expect("Expected rebase sha"),
            operation: action_data.pop().expect("Expected rebase operation"),
        }
    }
}

struct RebaseData {
    rebase_file: String,
    actions: Vec<RebaseAction>,
    comments: Vec<String>,
    first_frame: bool,
    columns: [f32; 2],
    line_height: f32,
    item_height: f32,
    spacing: f32,
    drag_index: Option<usize>,
    drag_offset: [f32; 2],
    drag_dest: Option<usize>,
    button_padding: [f32; 2],
}

impl RebaseData {
    fn new(rebase_file: String) -> Self {
        let mut data = RebaseData {
            rebase_file,
            actions: Vec::new(),
            comments: Vec::new(),
            first_frame: true,
            columns: [60.0, 150.0],
            line_height: 10.0,
            item_height: 10.0,
            spacing: 3.0,
            drag_index: None,
            drag_offset: [0.0, 0.0],
            drag_dest: None,
            button_padding: [0.0, 0.0],
        };
        let file = std::fs::File::open(&data.rebase_file).expect("Unable to open rebase file");
        let lines = std::io::BufReader::new(file).lines();
        for line in lines {
            if let Ok(line) = line {
                if line.starts_with('|') {
                    data.comments.push(line);
                } else if !line.is_empty() {
                    data.actions.push(RebaseAction::new(line));
                }
            }
        }
        data
    }
}

impl AppData for RebaseData {
    fn default_window_size(&mut self) -> winit::dpi::PhysicalSize<u32> {
        let line_count = self.actions.len() + self.comments.len() + 2;
        winit::dpi::PhysicalSize::new(700, std::cmp::min((line_count * 20) as u32, 980))
    }

    fn init(&mut self, imgui: &imgui::Context) {
        self.button_padding = imgui.style().frame_padding;
    }

    fn frame(&mut self, ui: &mut Ui, size: winit::dpi::PhysicalSize<u32>) -> bool {
        if self.first_frame {
            self.first_frame = false;
            let spacing = 15.0;
            let sha_size = ui.calc_text_size(im_str!("WWWWWWWWW"), false, -1.0);
            self.columns[0] = ui.calc_text_size(im_str!("WWWWWWW"), false, -1.0)[0] + spacing;
            self.columns[1] = self.columns[0] + sha_size[0] + spacing;
            self.line_height = sha_size[1];
            self.item_height = self.line_height + self.spacing;
        }
        let mut quit = false;
        Window::new(im_str!("App"))
            .size(
                [size.width as f32 - 4.0, size.height as f32 - 4.0],
                Condition::Always,
            )
            .position([0.0, 0.0], Condition::FirstUseEver)
            .flags(WindowFlags::NO_TITLE_BAR | WindowFlags::NO_MOVE | WindowFlags::NO_RESIZE)
            .build(
                &ui,
                #[allow(clippy::cognitive_complexity)]
                || {
                    if ui.is_key_released(VirtualKeyCode::W as u32)
                        && (ui.is_key_down(VirtualKeyCode::LControl as u32)
                            || ui.is_key_down(VirtualKeyCode::RControl as u32))
                    {
                        quit = true;
                        return;
                    }

                    let offset = ui.cursor_screen_pos();

                    let abort_text = im_str!("Abort");
                    let button_text_size = ui.calc_text_size(&abort_text, true, -1.0);
                    let mut abort_pos = ui.window_content_region_max();
                    let button_size = [
                        button_text_size[0] + 2.0 * self.button_padding[0],
                        button_text_size[1] + 2.0 * self.button_padding[1],
                    ];
                    abort_pos[0] -= button_size[0];
                    abort_pos[1] -= button_size[1];
                    ui.set_cursor_screen_pos(abort_pos);
                    if ui.button(abort_text, button_size) {
                        std::process::exit(1);
                    }

                    let mut move_index = None;
                    let mut move_dest = None;
                    if !ui.is_any_item_active() {
                        if self.drag_index.is_some() && self.drag_dest.is_some() {
                            move_index = self.drag_index;
                            move_dest = self.drag_dest;
                        }
                        self.drag_index = None;
                        self.drag_offset = [0.0, 0.0];
                        self.drag_dest = None;
                    }
                    if !ui.is_mouse_dragging(imgui::MouseButton::Left) {
                        if let Some(move_index) = move_index {
                            if let Some(move_dest) = move_dest {
                                let action = self.actions.remove(move_index);
                                if move_dest >= self.actions.len() {
                                    self.actions.push(action);
                                } else {
                                    self.actions.insert(move_dest, action);
                                }
                            }
                        }
                    }

                    for (commit_index, action) in self.actions.iter_mut().enumerate() {
                        let mut reorder_offset = 0.0;
                        let commit_id = ui.push_id(action.sha.as_str());
                        if let Some(drag_index) = self.drag_index {
                            if let Some(drag_dest) = self.drag_dest {
                                if commit_index > drag_index && drag_dest >= commit_index {
                                    reorder_offset = -1.0 * self.item_height;
                                } else if commit_index < drag_index && drag_dest <= commit_index {
                                    reorder_offset = self.item_height
                                }
                            }
                        }
                        let mut pos = [
                            offset[0],
                            reorder_offset + offset[1] + commit_index as f32 * self.item_height,
                        ];
                        if let Some(index) = self.drag_index {
                            if commit_index == index {
                                pos[0] += self.drag_offset[0];
                                pos[1] += self.drag_offset[1];
                            }
                        }
                        let canvas_max = ui.window_content_region_max();
                        let sha_string = ImString::new(&action.sha);
                        ui.set_cursor_screen_pos(pos);
                        ui.invisible_button(
                            &sha_string,
                            [canvas_max[0] - pos[0], self.line_height],
                        );
                        if ui.is_item_hovered() {
                            let draw_list = ui.get_window_draw_list();
                            let color = if ui.is_item_active() {
                                im_color!(200, 200, 200)
                            } else {
                                im_color!(100, 100, 100)
                            };
                            draw_list
                                .add_rect(pos, [canvas_max[0], pos[1] + self.line_height], color)
                                .build();
                            if ui.is_key_pressed(VirtualKeyCode::P as u32) {
                                action.operation = "pick".to_string();
                            } else if ui.is_key_pressed(VirtualKeyCode::R as u32) {
                                action.operation = "reword".to_string();
                            } else if ui.is_key_pressed(VirtualKeyCode::E as u32) {
                                action.operation = "edit".to_string();
                            } else if ui.is_key_pressed(VirtualKeyCode::S as u32) {
                                action.operation = "squash".to_string();
                            } else if ui.is_key_pressed(VirtualKeyCode::F as u32) {
                                action.operation = "fixup".to_string();
                            } else if ui.is_key_pressed(VirtualKeyCode::B as u32) {
                                action.operation = "break".to_string();
                            } else if ui.is_key_pressed(VirtualKeyCode::D as u32) {
                                action.operation = "drop".to_string();
                            } else if ui.is_key_pressed(VirtualKeyCode::T as u32) {
                                self.drag_index = Some(commit_index);
                                self.drag_dest = Some(0);
                            }
                        }
                        if ui.is_item_active() && ui.is_mouse_dragging(imgui::MouseButton::Left) {
                            self.drag_index = Some(commit_index);
                            let delta = ui.io().mouse_delta;
                            self.drag_offset[1] += delta[1];
                            let relative_mouse_pos = ui.io().mouse_pos[1] - offset[1];
                            if relative_mouse_pos >= 0.0 {
                                self.drag_dest =
                                    Some((relative_mouse_pos / self.item_height) as usize);
                            } else {
                                self.drag_dest = Some(0);
                            }
                        }

                        ui.set_cursor_screen_pos(pos);
                        ui.text(ImString::new(&action.operation));
                        ui.same_line(self.columns[0]);
                        ui.text(ImString::new(&action.sha));
                        ui.same_line(self.columns[1]);
                        ui.text(ImString::new(&action.message));
                        commit_id.pop(&ui);
                    }

                    let pos = [
                        offset[0],
                        offset[1] + (self.actions.len() + 2) as f32 * self.item_height,
                    ];
                    ui.set_cursor_screen_pos(pos);
                    for comment in self.comments.iter() {
                        let comment_string = ImString::new(comment);
                        ui.text(comment_string);
                    }
                },
            );
        quit
    }

    fn exit(&mut self) {
        println!();
        let mut file = std::fs::OpenOptions::new()
            .write(true)
            .truncate(true)
            .open(&self.rebase_file)
            .expect("Unable to open rebase file");
        for action in self.actions.iter() {
            println!("{} {} {}", action.operation, action.sha, action.message);
            writeln!(
                file,
                "{} {} {}",
                action.operation, action.sha, action.message
            )
            .expect("Unable to write to rebase file");
        }
    }
}

fn main() {
    let args: Vec<String> = std::env::args().skip(1).collect();

    if !args.is_empty()
        && (args[0].ends_with("COMMIT_EDITMSG") || args[0].ends_with("addp-hunk-edit.diff"))
    {
        let env = env_logger::Env::default().filter_or("BAS_LOG_LEVEL", "info");

        env_logger::Builder::from_env(env)
            .format(|buf, record| {
                writeln!(
                    buf,
                    "{} {} {}: {}",
                    Local::now().format("%Y-%m-%dT%H:%M:%S"),
                    buf.default_styled_level(record.level()),
                    record.target(),
                    record.args()
                )
            })
            .init();

        let data = Box::new(MessageData::new(args[0].clone()));
        imgui_app(data);
    } else {
        let use_qt = false;

        if use_qt {
            use std::process::Command;
            let status = Command::new("git-editor-qt.exe")
                .args(args)
                .status()
                .expect("failed to execute git-editor-qt");

            let code = status.code().unwrap_or(1);
            std::process::exit(code);
        } else {
            let data = Box::new(RebaseData::new(args[0].clone()));
            imgui_app(data);
        }
    }
}
