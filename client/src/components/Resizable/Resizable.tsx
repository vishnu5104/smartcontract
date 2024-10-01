import { forwardRef } from "react";
import {
  Resizable as ReResizable,
  ResizableProps as ReResizableProps,
  Enable,
} from "re-resizable";

type ResizableProps = Omit<ReResizableProps, "enable"> & {
  enable?: Enable | "top" | "right" | "bottom" | "left";
};

const Resizable = forwardRef<ReResizable, ResizableProps>((props, ref) => (
  <ReResizable
    ref={ref}
    {...{ ...props, enable: transformEnable(props.enable) }}
  ></ReResizable>
));

const transformEnable = (
  enable: ResizableProps["enable"]
): ReResizableProps["enable"] => {
  if (!enable || typeof enable === "object") return enable;

  const KEYS: Array<keyof Enable> = [
    "bottom",
    "bottomLeft",
    "bottomRight",
    "left",
    "right",
    "top",
    "topLeft",
    "topRight",
  ];
  const ALL_FALSE = Object.values(KEYS).reduce((acc, cur) => {
    acc[cur] = false;
    return acc;
  }, {} as Enable);

  switch (enable) {
    case "bottom":
      return { ...ALL_FALSE, bottom: true };
    case "left":
      return { ...ALL_FALSE, left: true };
    case "right":
      return { ...ALL_FALSE, right: true };
    case "top":
      return { ...ALL_FALSE, top: true };
  }
};

export default Resizable;
